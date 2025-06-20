// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"fmt"
	"log"
	"math/rand"
	"os"
	"strings"
	"testing"

	"github.com/IBM/go-sdk-core/v5/core"
	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testaddons"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"
const resourceGroup = "geretain-test-observability-instances"

const solutionInstanceDADir = "solutions/instances"
const solutionAgentsDADir = "solutions/agents"
const solutionTenantsDADir = "solutions/logs-routing"
const agentsKubeconfigDir = "solutions/agents/kubeconfig"

var IgnoreInstanceUpdates = []string{
	// Need to ignore this since primary_metadata_region might be updating in the dev account due to tests using different regions
	"module.metrics_router.ibm_metrics_router_settings.metrics_router_settings[0]",
}

var IgnoreAgentsUpdates = []string{
	"module.observability_agents.module.logs_agent[0].helm_release.logs_agent",
	"module.observability_agents.helm_release.cloud_monitoring_agent[0]",
}

// Currently only including regions that Event Notification support
var validRegions = []string{
	"au-syd",
	"eu-gb",
	"eu-de",
	"eu-es",
	"us-south",
}

var sharedInfoSvc *cloudinfo.CloudInfoService

var permanentResources map[string]interface{}

func TestMain(m *testing.M) {
	sharedInfoSvc, _ = cloudinfo.NewCloudInfoServiceFromEnv("TF_VAR_ibmcloud_api_key", cloudinfo.CloudInfoServiceOptions{})

	// Read the YAML file contents
	var err error
	permanentResources, err = common.LoadMapFromYaml(yamlLocation)
	if err != nil {
		log.Fatal(err)
	}

	os.Exit(m.Run())
}

func TestInstancesInSchematics(t *testing.T) {
	t.Parallel()

	var region = validRegions[rand.Intn(len(validRegions))]

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		Prefix:  "instance-da",
		TarIncludePatterns: []string{
			"*.tf",
			solutionInstanceDADir + "/*.tf",
		},
		ResourceGroup:          resourceGroup,
		TemplateFolder:         solutionInstanceDADir,
		Tags:                   []string{"test-schematic"},
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 60,
		IgnoreUpdates: testhelper.Exemptions{
			List: IgnoreInstanceUpdates,
		},
	})

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "resource_group_name", Value: resourceGroup, DataType: "string"},
		{Name: "existing_kms_instance_crn", Value: permanentResources["hpcs_south_crn"], DataType: "string"},
		{Name: "cos_region", Value: region, DataType: "string"},
		{Name: "cos_instance_tags", Value: options.Tags, DataType: "list(string)"},
		{Name: "cloud_logs_tags", Value: options.Tags, DataType: "list(string)"},
		{Name: "cloud_monitoring_tags", Value: options.Tags, DataType: "list(string)"},
		{Name: "enable_platform_metrics", Value: false, DataType: "bool"},
		{Name: "cos_instance_access_tags", Value: permanentResources["accessTags"], DataType: "list(string)"},
		{Name: "at_cos_bucket_access_tags", Value: permanentResources["accessTags"], DataType: "list(string)"},
		{Name: "cloud_log_data_bucket_access_tag", Value: permanentResources["accessTags"], DataType: "list(string)"},
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
	}

	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}

func TestRunUpgradeSolutionInstances(t *testing.T) {
	t.Parallel()

	var region = validRegions[rand.Intn(len(validRegions))]

	options := testhelper.TestOptionsDefault(&testhelper.TestOptions{
		Testing:      t,
		TerraformDir: solutionInstanceDADir,
		Region:       region,
		Prefix:       "obs-ins-upg",
		IgnoreUpdates: testhelper.Exemptions{
			List: IgnoreInstanceUpdates,
		},
	})

	options.TerraformVars = map[string]interface{}{
		"prefix":                              options.Prefix,
		"resource_group_name":                 resourceGroup,
		"cos_instance_access_tags":            permanentResources["accessTags"],
		"existing_kms_instance_crn":           permanentResources["hpcs_south_crn"],
		"kms_endpoint_type":                   "public",
		"provider_visibility":                 "public",
		"management_endpoint_type_for_bucket": "public",
		"enable_platform_metrics":             "false",
		"region":                              options.Region,
		"cloud_logs_policies": []map[string]interface{}{
			{
				"logs_policy_name":     "upg-test-policy",
				"logs_policy_priority": "type_low",
				"log_rules": []map[string]interface{}{
					{
						"severities": []string{"info", "debug"},
					},
				},
			},
		},
	}

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}

func TestAgentsSolutionInSchematics(t *testing.T) {
	t.Parallel()

	var region = validRegions[rand.Intn(len(validRegions))]

	// ------------------------------------------------------------------------------------------------------
	// Deploy SLZ ROKS Cluster and Observability instances since it is needed to deploy Observability Agents
	// ------------------------------------------------------------------------------------------------------

	prefix := fmt.Sprintf("slz-%s", strings.ToLower(random.UniqueId()))
	realTerraformDir := "./resources"
	tempTerraformDir, _ := files.CopyTerraformFolderToTemp(realTerraformDir, fmt.Sprintf(prefix+"-%s", strings.ToLower(random.UniqueId())))

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")

	logger.Log(t, "Tempdir: ", tempTerraformDir)
	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempTerraformDir,
		Vars: map[string]interface{}{
			"prefix": prefix,
			"region": region,
		},
		// Set Upgrade to true to ensure latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})

	terraform.WorkspaceSelectOrNew(t, existingTerraformOptions, prefix)
	_, existErr := terraform.InitAndApplyE(t, existingTerraformOptions)

	if existErr != nil {
		assert.True(t, existErr == nil, "Init and Apply of temp resources (SLZ-ROKS and Observability Instances) failed")
	} else {

		options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
			Testing: t,
			Prefix:  "obs-agents",
			TarIncludePatterns: []string{
				solutionAgentsDADir + "/*.*",
				agentsKubeconfigDir + "/*.*",
			},
			ResourceGroup:          resourceGroup,
			TemplateFolder:         solutionAgentsDADir,
			Tags:                   []string{"test-schematic"},
			DeleteWorkspaceOnFail:  false,
			WaitJobCompleteMinutes: 60,
			Region:                 region,
			IgnoreUpdates: testhelper.Exemptions{ // Ignore for consistency check
				List: IgnoreAgentsUpdates,
			},
		})

		options.TerraformVars = []testschematic.TestSchematicTerraformVar{
			{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
			{Name: "cloud_monitoring_instance_region", Value: region, DataType: "string"},
			{Name: "cluster_id", Value: terraform.Output(t, existingTerraformOptions, "cluster_id"), DataType: "string"},
			{Name: "logs_agent_trusted_profile", Value: terraform.Output(t, existingTerraformOptions, "trusted_profile_id"), DataType: "string"},
			{Name: "cloud_logs_ingress_endpoint", Value: terraform.Output(t, existingTerraformOptions, "cloud_logs_ingress_private_endpoint"), DataType: "string"},
			{Name: "cluster_resource_group_id", Value: terraform.Output(t, existingTerraformOptions, "resource_group_id"), DataType: "string"},
			{Name: "cloud_monitoring_access_key", Value: terraform.Output(t, existingTerraformOptions, "cloud_monitoring_access_key"), DataType: "string", Secure: true},
			{Name: "prefix", Value: options.Prefix, DataType: "string"},
		}

		err := options.RunSchematicTest()
		assert.Nil(t, err, "This should not have errored")
	}

	// Check if "DO_NOT_DESTROY_ON_FAILURE" is set
	envVal, _ := os.LookupEnv("DO_NOT_DESTROY_ON_FAILURE")
	// Destroy the temporary existing resources if required
	if t.Failed() && strings.ToLower(envVal) == "true" {
		fmt.Println("Terratest failed. Debug the test and delete resources manually.")
	} else {
		logger.Log(t, "START: Destroy (existing resources)")
		terraform.Destroy(t, existingTerraformOptions)
		terraform.WorkspaceDelete(t, existingTerraformOptions, prefix)
		logger.Log(t, "END: Destroy (existing resources)")
	}
}

func TestRunExistingResourcesInstancesSchematics(t *testing.T) {
	t.Parallel()

	// ------------------------------------------------------------------------------------
	// Provision COS & EN first
	// ------------------------------------------------------------------------------------

	prefix := fmt.Sprintf("obs-exist-%s", strings.ToLower(random.UniqueId()))
	realTerraformDir := "./resources/existing-resources"
	tempTerraformDir, _ := files.CopyTerraformFolderToTemp(realTerraformDir, fmt.Sprintf(prefix+"-%s", strings.ToLower(random.UniqueId())))
	tags := common.GetTagsFromTravis()

	var region = validRegions[rand.Intn(len(validRegions))]

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")

	logger.Log(t, "Tempdir: ", tempTerraformDir)
	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempTerraformDir,
		Vars: map[string]interface{}{
			"prefix":        prefix,
			"region":        region,
			"resource_tags": tags,
		},
		Upgrade: true,
	})

	terraform.WorkspaceSelectOrNew(t, existingTerraformOptions, prefix)
	_, existErr := terraform.InitAndApplyE(t, existingTerraformOptions)

	cloud_logs_existing_en_instances := []map[string]interface{}{
		{
			"instance_crn":     terraform.Output(t, existingTerraformOptions, "en_crn_2"),
			"integration_name": "en-2",
		},
	}

	cloud_logs_policies := []map[string]interface{}{
		{
			"logs_policy_name":     "test-policy",
			"logs_policy_priority": "type_low",
			"log_rules": []map[string]interface{}{
				{
					"severities": []string{"info"},
				},
			},
		},
	}

	if existErr != nil {
		assert.True(t, existErr == nil, "Init and Apply of temp existing resource failed")
	} else {
		options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
			Testing: t,
			Prefix:  "obs-ins-ext",
			TarIncludePatterns: []string{
				solutionInstanceDADir + "/*.*",
			},
			ResourceGroup:          terraform.Output(t, existingTerraformOptions, "resource_group_name"),
			TemplateFolder:         solutionInstanceDADir,
			Tags:                   []string{"test-schematic"},
			DeleteWorkspaceOnFail:  false,
			WaitJobCompleteMinutes: 60,
			Region:                 region,
			IgnoreUpdates: testhelper.Exemptions{
				List: IgnoreInstanceUpdates,
			},
		})

		options.TerraformVars = []testschematic.TestSchematicTerraformVar{
			{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
			{Name: "region", Value: region, DataType: "string"},
			{Name: "cos_region", Value: region, DataType: "string"},
			{Name: "resource_group_name", Value: terraform.Output(t, existingTerraformOptions, "resource_group_name"), DataType: "string"},
			{Name: "existing_cloud_logs_data_bucket_crn", Value: terraform.Output(t, existingTerraformOptions, "data_bucket_crn"), DataType: "string"},
			{Name: "existing_at_cos_target_bucket_name", Value: terraform.Output(t, existingTerraformOptions, "bucket_name_at"), DataType: "string"},
			{Name: "existing_at_cos_target_bucket_endpoint", Value: terraform.Output(t, existingTerraformOptions, "bucket_endpoint_at"), DataType: "string"},
			{Name: "existing_cloud_logs_data_bucket_endpoint", Value: terraform.Output(t, existingTerraformOptions, "data_bucket_endpoint"), DataType: "string"},
			{Name: "existing_cloud_logs_metrics_bucket_crn", Value: terraform.Output(t, existingTerraformOptions, "metrics_bucket_crn"), DataType: "string"},
			{Name: "existing_cloud_logs_metrics_bucket_endpoint", Value: terraform.Output(t, existingTerraformOptions, "metrics_bucket_endpoint"), DataType: "string"},
			{Name: "existing_en_instance_crn", Value: terraform.Output(t, existingTerraformOptions, "en_crn_1"), DataType: "string"},
			{Name: "prefix", Value: options.Prefix, DataType: "string"},
			{Name: "management_endpoint_type_for_bucket", Value: "private", DataType: "string"},
			{Name: "provider_visibility", Value: "public", DataType: "string"},
			{Name: "enable_platform_metrics", Value: false, DataType: "bool"},
			{Name: "cloud_logs_existing_en_instances", Value: cloud_logs_existing_en_instances, DataType: "list(object)"},
			{Name: "cloud_logs_policies", Value: cloud_logs_policies, DataType: "list(object)"},
			{Name: "existing_cos_instance_crn", Value: terraform.Output(t, existingTerraformOptions, "cos_crn"), DataType: "string"},
			{Name: "existing_cloud_monitoring_crn", Value: terraform.Output(t, existingTerraformOptions, "cloud_monitoring_crn"), DataType: "string"},
			{Name: "cloud_monitoring_provision", Value: false, DataType: "bool"},
		}

		err := options.RunSchematicTest()
		assert.Nil(t, err, "This should not have errored")

		options2 := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
			Testing: t,
			Prefix:  "obs-ext",
			TarIncludePatterns: []string{
				solutionInstanceDADir + "/*.*",
			},
			ResourceGroup:          terraform.Output(t, existingTerraformOptions, "resource_group_name"),
			TemplateFolder:         solutionInstanceDADir,
			Tags:                   []string{"test-schematic"},
			DeleteWorkspaceOnFail:  false,
			WaitJobCompleteMinutes: 60,
			Region:                 region,
			IgnoreUpdates: testhelper.Exemptions{
				List: IgnoreInstanceUpdates,
			},
		})

		options2.TerraformVars = []testschematic.TestSchematicTerraformVar{
			{Name: "ibmcloud_api_key", Value: options2.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
			{Name: "cos_region", Value: region, DataType: "string"},
			{Name: "prefix", Value: options2.Prefix, DataType: "string"},
			{Name: "resource_group_name", Value: terraform.Output(t, existingTerraformOptions, "resource_group_name"), DataType: "string"},
			{Name: "kms_endpoint_type", Value: "private", DataType: "string"},
			{Name: "existing_cos_instance_crn", Value: terraform.Output(t, existingTerraformOptions, "cos_crn"), DataType: "string"},
			{Name: "management_endpoint_type_for_bucket", Value: "private", DataType: "string"},
			{Name: "enable_platform_metrics", Value: false, DataType: "bool"},
			{Name: "existing_kms_instance_crn", Value: permanentResources["hpcs_south_crn"], DataType: "string"},
			{Name: "existing_cos_kms_key_crn", Value: permanentResources["hpcs_south_root_key_crn"], DataType: "string"},
		}

		err = options2.RunSchematicTest()
		assert.Nil(t, err, "This should not have errored")

	}

	envVal, _ := os.LookupEnv("DO_NOT_DESTROY_ON_FAILURE")
	// Destroy the temporary existing resources if required
	if t.Failed() && strings.ToLower(envVal) == "true" {
		fmt.Println("Terratest failed. Debug the test and delete resources manually.")
	} else {
		logger.Log(t, "START: Destroy (existing resources)")
		terraform.Destroy(t, existingTerraformOptions)
		terraform.WorkspaceDelete(t, existingTerraformOptions, prefix)
		logger.Log(t, "END: Destroy (existing resources)")
	}
}

func TestTenantsInSchematics(t *testing.T) {
	t.Skip("Skipping test until https://github.ibm.com/GoldenEye/issues/issues/10676 is complete")
	t.Parallel()

	tenant_configuration := []map[string]interface{}{
		{
			"tenant_region": "jp-osa",
			"tenant_name":   "test-tenant",
			"target_name":   "test-target",
			"log_sink_crn":  permanentResources["cloud_logs_instance_crn"],
		},
	}

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		TarIncludePatterns: []string{
			"*.tf",
			solutionTenantsDADir + "/*.tf",
		},
		TemplateFolder:         solutionTenantsDADir,
		Tags:                   []string{"test-schematic"},
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 60,
	})

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "tenant_configuration", Value: tenant_configuration, DataType: "list(object)"},
	}

	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}

func TestTenantsUpgradeTest(t *testing.T) {
	t.Skip("Skipping test until https://github.ibm.com/GoldenEye/issues/issues/10676 is complete")
	t.Parallel()

	tenant_configuration := []map[string]interface{}{
		{
			"tenant_region": "br-sao",
			"tenant_name":   "test-tenant",
			"target_name":   "test-target",
			"log_sink_crn":  permanentResources["cloud_logs_instance_crn"],
		},
	}

	options := testhelper.TestOptionsDefault(&testhelper.TestOptions{
		Testing:      t,
		TerraformDir: solutionTenantsDADir,
	})

	options.TerraformVars = map[string]interface{}{
		"tenant_configuration": tenant_configuration,
	}

	_, err := options.RunTestUpgrade()
	assert.Nil(t, err, "This should not have errored")
}

// TestRunAddonTests runs addon tests in parallel using a matrix approach
func TestRunAddonInstanceTests(t *testing.T) {

	testCases := []testaddons.AddonTestCase{
		{
			Name:   "Default",
			Prefix: "obsadd",
		},
		{
			Name:                         "ValidateRGOnlyOn",
			Prefix:                       "obsadd",
			SkipInfrastructureDeployment: true, // Validate complex dependencies without deployment cost
			Dependencies: []cloudinfo.AddonConfig{
				{
					OfferingName:   "deploy-arch-ibm-account-infra-base",
					OfferingFlavor: "resource-groups-only",
					Enabled:        core.BoolPtr(true),
				},
			},
		},
		{
			Name:                         "ValidateRGWithAccountSettingsOn",
			Prefix:                       "obsadd",
			SkipInfrastructureDeployment: true, // Validate complex dependencies without deployment cost
			Dependencies: []cloudinfo.AddonConfig{
				{
					OfferingName:   "deploy-arch-ibm-account-infra-base",
					OfferingFlavor: "resource-groups-with-account-settings",
					Enabled:        core.BoolPtr(true),
				},
			},
		},
		{
			Name:                         "ValidateKMSOff",
			Prefix:                       "obsadd",
			SkipInfrastructureDeployment: true, // Validate complex dependencies without deployment cost
			Inputs: map[string]interface{}{
				"existing_kms_instance_crn": permanentResources["hpcs_south_crn"],
			},
			Dependencies: []cloudinfo.AddonConfig{
				{
					OfferingName:   "deploy-arch-ibm-kms",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(false),
				},
			},
		},
	}

	matrix := testaddons.AddonTestMatrix{
		TestCases: testCases,
		BaseSetupFunc: func(testCase testaddons.AddonTestCase) *testaddons.TestAddonOptions {
			return testaddons.TestAddonsOptionsDefault(&testaddons.TestAddonOptions{
				Testing:       t,
				Prefix:        testCase.Prefix,
				ResourceGroup: resourceGroup,
			})
		},
		AddonConfigFunc: func(options *testaddons.TestAddonOptions, testCase testaddons.AddonTestCase) cloudinfo.AddonConfig {
			return cloudinfo.NewAddonConfigTerraform(
				options.Prefix,
				"deploy-arch-ibm-observability",
				"instances",
				map[string]interface{}{
					"prefix":                  options.Prefix,
					"region":                  "us-south",
					"enable_platform_metrics": false,
				},
			)
		},
	}

	testaddons.RunAddonTestMatrix(t, matrix)
}

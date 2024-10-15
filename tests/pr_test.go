// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"fmt"
	"log"
	"math/rand"
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"
const resourceGroup = "geretain-test-observability-instances"

const solutionInstanceDADir = "solutions/instances"
const solutionAgentsDADir = "solutions/agents"
const agentsKubeconfigDir = "solutions/agents/kubeconfig"

// Current supported regions for Observability instances
var validRegions = []string{
	"au-syd",
	"eu-de",
	"eu-es",
	"eu-gb",
	"jp-osa",
	"jp-tok",
	"us-south",
	"us-east",
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
	})

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "resource_group_name", Value: options.Prefix, DataType: "string"},
		{Name: "existing_kms_instance_crn", Value: permanentResources["hpcs_south_crn"], DataType: "string"},
		{Name: "cos_region", Value: region, DataType: "string"},
		{Name: "cos_instance_tags", Value: options.Tags, DataType: "list(string)"},
		{Name: "cloud_logs_tags", Value: options.Tags, DataType: "list(string)"},
		{Name: "enable_platform_logs", Value: false, DataType: "bool"},
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

	options := testhelper.TestOptionsDefault(&testhelper.TestOptions{
		Testing:      t,
		TerraformDir: solutionInstanceDADir,
		Region:       "us-south",
		Prefix:       "obs-ins-upg",
	})

	options.TerraformVars = map[string]interface{}{
		"prefix":                              options.Prefix,
		"resource_group_name":                 options.Prefix,
		"cos_instance_access_tags":            permanentResources["accessTags"],
		"existing_kms_instance_crn":           permanentResources["hpcs_south_crn"],
		"kms_endpoint_type":                   "public",
		"management_endpoint_type_for_bucket": "public",
		"log_analysis_service_endpoints":      "public-and-private",
		"enable_platform_logs":                "false",
		"enable_platform_metrics":             "false",
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
		})

		options.TerraformVars = []testschematic.TestSchematicTerraformVar{
			{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
			{Name: "cloud_monitoring_instance_region", Value: region, DataType: "string"},
			{Name: "cluster_id", Value: terraform.Output(t, existingTerraformOptions, "workload_cluster_id"), DataType: "string"},
			{Name: "logs_agent_trusted_profile", Value: terraform.Output(t, existingTerraformOptions, "trusted_profile_id"), DataType: "string"},
			{Name: "cloud_logs_ingress_endpoint", Value: terraform.Output(t, existingTerraformOptions, "cloud_logs_ingress_private_endpoint"), DataType: "string"},
			{Name: "cluster_resource_group_id", Value: terraform.Output(t, existingTerraformOptions, "cluster_resource_group_id"), DataType: "string"},
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

func TestRunExistingResourcesInstances(t *testing.T) {
	t.Parallel()

	// ------------------------------------------------------------------------------------
	// Provision COS & EN first
	// ------------------------------------------------------------------------------------

	prefix := fmt.Sprintf("obs-exist-%s", strings.ToLower(random.UniqueId()))
	realTerraformDir := "./resources/existing-resources"
	tempTerraformDir, _ := files.CopyTerraformFolderToTemp(realTerraformDir, fmt.Sprintf(prefix+"-%s", strings.ToLower(random.UniqueId())))
	tags := common.GetTagsFromTravis()
	region := "us-south"

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
		// Set Upgrade to true to ensure latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})

	terraform.WorkspaceSelectOrNew(t, existingTerraformOptions, prefix)
	_, existErr := terraform.InitAndApplyE(t, existingTerraformOptions)
	if existErr != nil {
		assert.True(t, existErr == nil, "Init and Apply of temp existing resource failed")
	} else {

		// ------------------------------------------------------------------------------------
		// Deploy Observability instances DA passing in existing COS instance, and bucket details
		// ------------------------------------------------------------------------------------

		options := testhelper.TestOptionsDefault(&testhelper.TestOptions{
			Testing:      t,
			TerraformDir: solutionInstanceDADir,
			// Do not hard fail the test if the implicit destroy steps fail to allow a full destroy of resource to occur
			ImplicitRequired: false,
			Region:           region,
			TerraformVars: map[string]interface{}{
				"cos_region":                                  region,
				"resource_group_name":                         terraform.Output(t, existingTerraformOptions, "resource_group_name"),
				"use_existing_resource_group":                 true,
				"existing_at_cos_target_bucket_name":          terraform.Output(t, existingTerraformOptions, "bucket_name_at"),
				"existing_at_cos_target_bucket_endpoint":      terraform.Output(t, existingTerraformOptions, "bucket_endpoint_at"),
				"existing_cos_instance_crn":                   terraform.Output(t, existingTerraformOptions, "cos_crn"),
				"existing_cloud_logs_data_bucket_crn":         terraform.Output(t, existingTerraformOptions, "data_bucket_crn"),
				"existing_cloud_logs_data_bucket_endpoint":    terraform.Output(t, existingTerraformOptions, "data_bucket_endpoint"),
				"existing_cloud_logs_metrics_bucket_crn":      terraform.Output(t, existingTerraformOptions, "metrics_bucket_crn"),
				"existing_cloud_logs_metrics_bucket_endpoint": terraform.Output(t, existingTerraformOptions, "metrics_bucket_endpoint"),
				"existing_en_instance_crn":                    terraform.Output(t, existingTerraformOptions, "en_crn_1"),
				"cloud_logs_existing_en_instances": []map[string]interface{}{
					{
						"instance_crn": terraform.Output(t, existingTerraformOptions, "en_crn_2"),
					},
				},
				"management_endpoint_type_for_bucket": "public",
				"enable_platform_metrics":             "false",
				"enable_platform_logs":                "false",
			},
		})

		output, err := options.RunTestConsistency()
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")

		// ------------------------------------------------------------------------------------
		// Deploy Observability instance DA passing in existing COS instance (not bucket), and KMS key
		// ------------------------------------------------------------------------------------

		options2 := testhelper.TestOptionsDefault(&testhelper.TestOptions{
			Testing:      t,
			TerraformDir: solutionInstanceDADir,
			// Do not hard fail the test if the implicit destroy steps fail to allow a full destroy of resource to occur
			ImplicitRequired: false,
			TerraformVars: map[string]interface{}{
				"cos_region":                          region,
				"resource_group_name":                 terraform.Output(t, existingTerraformOptions, "resource_group_name"),
				"use_existing_resource_group":         true,
				"existing_kms_instance_crn":           permanentResources["hpcs_south_crn"],
				"kms_endpoint_type":                   "public",
				"existing_cos_instance_crn":           terraform.Output(t, existingTerraformOptions, "cos_crn"),
				"management_endpoint_type_for_bucket": "public",
				"enable_platform_metrics":             "false",
			},
		})

		output2, err := options2.RunTestConsistency()
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output2, "Expected some output")

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

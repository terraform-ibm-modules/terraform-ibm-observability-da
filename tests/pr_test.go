// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"log"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"
const resourceGroup = "geretain-test-observability-instances"
const solutionInstanceDADir = "solutions/instances"

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

	const region = "us-south"

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
		Region:                 region,
	})

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "resource_group_name", Value: options.Prefix, DataType: "string"},
		{Name: "existing_kms_guid", Value: permanentResources["hpcs_south"], DataType: "string"},
		{Name: "kms_region", Value: "us-south", DataType: "string"}, // KMS instance is in us-south
		{Name: "cos_region", Value: region, DataType: "string"},
		{Name: "cos_instance_tags", Value: options.Tags, DataType: "list(string)"},
		{Name: "log_analysis_tags", Value: options.Tags, DataType: "list(string)"},
		{Name: "cloud_monitoring_tags", Value: options.Tags, DataType: "list(string)"},
		{Name: "cos_instance_access_tags", Value: permanentResources["accessTags"], DataType: "list(string)"},
		{Name: "cos_bucket_access_tags", Value: permanentResources["accessTags"], DataType: "list(string)"},
	}

	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}

func TestRunUpgradeInstances(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefault(&testhelper.TestOptions{
		Testing:      t,
		TerraformDir: solutionInstanceDADir,
		Region:       "us-south",
		Prefix:       "obs-ins-upg",
	})

	options.TerraformVars = map[string]interface{}{
		"resource_group_name":                 options.Prefix,
		"cos_instance_access_tags":            permanentResources["accessTags"],
		"existing_kms_guid":                   permanentResources["hpcs_south"],
		"kms_endpoint_type":                   "public",
		"kms_region":                          "us-south",
		"management_endpoint_type_for_bucket": "public",
		"log_analysis_service_endpoints":      "public-and-private",
		"cloud_monitoring_service_endpoints":  "public",
	}

	output, err := options.RunTestUpgrade()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

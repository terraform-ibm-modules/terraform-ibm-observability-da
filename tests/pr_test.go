// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

// Use existing resource group
const resourceGroup = "geretain-test-observability-instances"

// const agentsSolutionDADir = "solutions/agents"
const testAgentsResourcesDir = "tests/resources"

// var sharedInfoSvc *cloudinfo.CloudInfoService

// Define a struct with fields that match the structure of the YAML data
// const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

// var permanentResources map[string]interface{}

// func TestMain(m *testing.M) {
// 	// Read the YAML file contents
// 	var err error
// 	permanentResources, err = common.LoadMapFromYaml(yamlLocation)
// 	if err != nil {
// 		log.Fatal(err)
// 	}

// 	os.Exit(m.Run())
// }

// func setupOptions(t *testing.T, prefix string, dir string) *testhelper.TestOptions {
// 	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
// 		Testing:       t,
// 		TerraformDir:  dir,
// 		Prefix:        prefix,
// 		ResourceGroup: resourceGroup,
// 	})
// 	return options
// }

func TestAgentsSolutionInSchematics(t *testing.T) {
	t.Parallel()

	const region = "us-south"

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		Prefix:  "obs-agents-da1",
		TarIncludePatterns: []string{
			"*.tf",
			testAgentsResourcesDir + "/*.tf",
		},
		// agentsSolutionDADir + "/*.tf",
		ResourceGroup:          resourceGroup,
		TemplateFolder:         testAgentsResourcesDir,
		Tags:                   []string{"test-schematic"},
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 240,
		Region:                 region,
	})

	// Workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/5154
	// options.AddWorkspaceEnvVar("IBMCLOUD_KP_API_ENDPOINT", "https://private."+region+".kms.cloud.ibm.com", false, false)

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "resource_tags", Value: options.Tags, DataType: "list(string)"},
		// {Name: "cloud_monitoring_access_key", Value: "dummy", DataType: "string"},
		// {Name: "log_analysis_ingestion_key", Value: "dummy", DataType: "string"},
		// {Name: "access_tags", Value: permanentResources["accessTags"], DataType: "list(string)"},
		// {Name: "keys", Value: []map[string]interface{}{{"key_ring_name": "my-key-ring", "keys": []map[string]interface{}{{"key_name": "some-key-name-1"}, {"key_name": "some-key-name-2"}}}}, DataType: "list(object)"},
	}

	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}

// func TestRunObservabilityAgentsSolution(t *testing.T) {
// 	t.Parallel()

// 	options := setupOptions(t, "obs-agent-da", agentsSolutionTerraformDir)

// 	output, err := options.RunTestConsistency()
// 	assert.Nil(t, err, "This should not have errored")
// 	assert.NotNil(t, output, "Expected some output")
// }

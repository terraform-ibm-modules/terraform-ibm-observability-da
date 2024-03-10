// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

// Use existing resource group
const resourceGroup = "geretain-test-observability-instances"

const testAgentsResourcesDir = "tests/resources"

func TestAgentsSolutionInSchematics(t *testing.T) {
	t.Parallel()

	const region = "us-south"

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		Prefix:  "prtest-agents",
		TarIncludePatterns: []string{
			"*.tf",
			testAgentsResourcesDir + "/*.tf",
		},
		ResourceGroup:          resourceGroup,
		TemplateFolder:         testAgentsResourcesDir,
		Tags:                   []string{"test-schematic"},
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 240,
		Region:                 region,
	})

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "resource_tags", Value: options.Tags, DataType: "list(string)"},
	}

	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}

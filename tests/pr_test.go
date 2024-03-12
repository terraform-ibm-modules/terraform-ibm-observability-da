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
)

const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"
const resourceGroup = "geretain-test-observability-instances"
const solutionInstanceTerraformDir = "solutions/instances"
const region = "us-south"

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

func TestRunInstanceSolution(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefault(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  solutionInstanceTerraformDir,
		Region:        region,
		ResourceGroup: resourceGroup,
	})

	options.TerraformVars = map[string]interface{}{
		"cos_instance_access_tags": permanentResources["accessTags"],
		"existing_kms_guid":        permanentResources["hpcs_south"],
		"existing_resource_group":  true,
		"resource_group_name":      options.ResourceGroup,
	}

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

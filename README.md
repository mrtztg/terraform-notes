# Raw notes/practice

- Install Terraform
- Provision AWS EC2 insatnce
- Mind about state file, 'resources' and 'data' section in it. Also secure it, since it'll have sensitive data inside
  like credentials.
- `.terraform` directory
- `init`, `plan`, `apply` and `destroy` commands of terraform
- Input Variables:
    - Manual entry during plan/apply (if none of the below been set)
    - Default value in declaration block
    - `TF_VAR_<name>` environment variable
    - `terraform.tfvars` file
    - `*.auto.tfvars` file
    - Command like `-var` or `-var-file`
- Local Variables:
    - We define them in each terraform files like `local {<attr-name> = <attr-value> , ...}`
    - Then use like `local.<attr-name>`
- Types:
    - string
    - number
    - bool
    - list(<type>)
    - set(<type>)
    - map(<type>)
    - object({<attr-name> = <type>, ...})
    - tuple([<type>, ...])
- Validation:
    - Type checking happens automatically
    - Custom conditions
- Sensitive data
    - `sensitive = true` to mark variable as sensitive
    - `TF_VAR_variale` or `-var` (retrieved from secret manager at runtime) to pass Terraform
    - Terraform will mark this data in *Plan* and *Apply* explanation
- Expressions
    - Template strings (like `ID: ${var.id}`)
    - Operators (`!,-,*,/,%,>,==`, etc)
    - Conditions (`cond ? true : false`)
    - For (`[for o in var.list : o.id]`)
    - Splat (`var.list[*].id`)
    - Dynamic Blocks
    - Constraints (Type & Version)
- Functions
  - Numeric (like math functions)
  - String
  - Collection
  - Encoding
  - Filesystem
  - Date & Time
  - Hash & Crypto
  - IP Network
  - Type Conversion
- # TODO: Practice Meta-arguments and Provisioners
- Meta-Arguments:
  - `depends_on`
    - Terraform knows the which resources depends on which and follows the proper order of config.
    - But there are scenarios 2 resources depends on each other, but there is no direct connection within the config. For example, we know our application in te EC2 instance need S3 access, but the TF config doesn't know this. So, we should use `depends_on` in EC2 to say that IAM role should be created before this EC2 instance.
  - `count`
    - It says how many copies of this resource to create
  - `for_each`
    - Lets us copy resources, while still have the necessary control on each
  - `Lifecycle`
    - control terraform behaviour on specific resource, like `create_before_destroy`, `ignore changes`, `prevent_destroy`
- Provisioners (E.g, we want to combine Terraform with Ansible configurations)
  - file
  - local-exec
  - remote-exec
  - vendor
    - chef
    - puppet
- Modules
  - Goal? Different teams & users can have their own scope of terraform configuration
  - Types: Root Module, Child Module
  - Module sources:
    - Local paths, Terraform Registry, Github, Bitbucket, Generic Git and Mercurial repos, HTTP URLs, S3 Buckets, GCS buckets
  - Child Modules can have access to things from parent module or even siblings, like their variables.
  - What makes a Good module?
    - Doesn't just separate by resource type.
    - Group resources in a logical manner. Like "game module" or "analytics module"
    - Provide useful defaults
    - Expose input values to allow necessary customization + composition. For example, domain name, ec2 instance type, db name, so on better to exposed
    - Return outputs to make further integrations possible
- Two approaches for having multiple environments (like dev, prod) with one config:

|      | Workspaces                                                                                                                                                                       | File Structure                                                                                                                     |
|------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------|
| Pros | Easy to get started<br>Convenient `terraform.workspace` expression<br>Minimizes code duplication                                                                                 | Isolation of backends:<br>- Improved security<br>- Decreased potential for human error<br>Codebase fully represents deployed state |
| Cons | Prone to human error (especially when you do manual changes on infra)<br>All states stored withing same backend<br>Codebase doesn't unambiguously show deployment configurations | Multiple `terraform apply` required to provision environments<br>Mor code duplication, but can be minimized with modules!          |

    - We also can use `Terragunt`


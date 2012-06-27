Lobot: Your Chief Administrative Aide on Cloud City
============================

![Lobot](http://i.imgur.com/QAkd7.jpg)
###Easily create your CI server on EC2

Lando Calrissian relies on Lobot to keep Cloud City afloat, and now you can rely on Lobot to get your continuous integration server running in the cloud. Lobot is a gem that will help you spin-up, bootstrap, and install Jenkins or TeamCity for CI for your Rails app on Amazon EC2.

# What do I get?

* Rake tasks for creating, starting, stopping, or destroying your CI server on EC2
* Capistrano tasks for bootstrapping the Centos EC2 instance
* Chef recipes for configuring the instance to run Jenkins and build Rails projects

After you add lobot to your Gemfile, all you'll need to do is run the following commands:

    rails g lobot:install [jenkins|teamcity]
    rails g lobot:config
    rake ci:create_server
    cap ci bootstrap
    cap ci chef

Read on for an explanation of what each one of these steps does.

## Install

Add lobot to your Gemfile, in the development group:

    gem "lobot", :group => :development

## Generate
Lobot is a Rails 3 generator.  Rails 2 can be made to work, but you will need to copy the template files into your project.

### For Jenkins:

    rails g lobot:install jenkins

### For TeamCity:
Lobot only creates your EC2 instance and installs the build server. Configuration for TeamCity still needs to be done manually.

    rails g lobot:install teamcity

## Setup
You can use a generator to interactively generate the config/ci.yml that includes some reasonable defaults and explanations.

    rails g lobot:config

Alternatively, manually edit config/ci.yml

    ---
    app_name: # a short name for your application
    app_user: # the user created to run your CI process
    git_location: # The location of your remote git repository which Jenkins will poll and pull from on changes.
    basic_auth:
    - username: # The username you will use to access the Jenkins web interface
      password: # The password you will use to access the Jenkins web interface
    credentials:
      aws_access_key_id: # The Access Key for your Amazon AWS account
      aws_secret_access_key: The Secret Access Key for your Amazon AWS account
      provider: AWS # leave this one alone
    server:
      name: run 'rake ci:create_server to populate'
      instance_id: run 'rake ci:create_server to populate'
    build_command: ./script/ci_build.sh
    ec2_server_access:
      key_pair_name: myapp_ci
      id_rsa_path: ~/.ssh/id_rsa
    github_private_ssh_key_path: ~/.ssh/id_rsa

## Adjust Defaults (Optional)
In your ci.yml, there are defaults set for values that have the recommened value. For example, the instance size used for EC2 is set to "m1.large", which costs $230/month.
If you don't need to increase your memory size for Jenkins or TeamCity, you could elect to use "c1.medium" instead which costs about half that.
You can also save on EC2 costs by using a tool like projectmonitor or ylastic to schedule when your instances are online.

For security, the lobot:install task added config/ci.yml to the .gitignore file since it includes sensitive AWS credentials and your CI users password.
Keep in mind that the default build script ci_build.sh uses the headless gem and jasmine. You'll want to add those to your Gemfile or change your build command.

## Commit and push your changes

At this point you will need to create a commit of the files generated or modified and push those changes to your remote git repository so Jenkins can execute your build command.

## Modify the soloistrc if necessary

Switch postgres to mysql, or add your own recipes for your own dependencies.

## Starting your lobot instance

1. Launch an instance, allocate and associates an elastic IP and updates ci.yml:

        rake ci:create_server

2. Bootstrap the instance using the boostrap_server.sh script generated by Lobot. The script instals ruby prerequisites, creates the app_user account, and installs RVM for that user:

        cap ci bootstrap

3. Upload the contents of your chef/cookbooks/ directory, upload the soloistrc, and run chef:

        cap ci chef

Your lobot instance should now be up and running. You will be able to access your CI server at: http://&lt;your instance address&gt;/ with the username and password you chose during configuration.
For more information about Jenkins CI, see http://jenkins-ci.org/

## Troubleshooting

Shell access for your instance

    rake ci:ssh

Terminating your instance and deallocating the elastic IP

    rake ci:destroy_server

Suspending your instance

    rake ci:stop_server

Rstarting a server

    rake ci:start_server

## Add your new CI instance to [projectmonitor](http://github.com/pivotal/projectmonitor) and CCMenu

Lobot can generate the config for you, just run:

    rake ci:info

## Color

Lobot installs the ansicolor plugin, however you need to configure rspec to generate colorful output. One way is to include `--color` in your .rspec and update your spec_helper.rb to include

``` ruby
RSpec.configure do |config|
 config.tty = true
end
```

## Dependencies

* fog
* capistrano
* capistrano-ext
* rvm (the gem - it configures capistrano to use RVM on the server)
* nokogiri

# Tests

Lobot is tested using rspec, generator_spec and cucumber.  Cucumber provides a full integration test which can generate a rails application, push it to github, start a server and bring up CI for the generated project.
You'll need a git repository (which should not have any code you care about) and an AWS account to run the whole test suite.  It costs about $0.50 and takes about half an hour.
It will attempt to terminate the server however you should verify this so you do not get charged additional money.
Use the secrets.yml.example to create a secrets.yml file with your account information.

# Contributing

Lobot is in its infancy and we welcome pull requests.  Pull requests should have test coverage for quick consideration.

# License

Lobot is MIT Licensed and © Pivotal Labs.  See LICENSE.txt for details.

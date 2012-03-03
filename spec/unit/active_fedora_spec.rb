require 'spec_helper'

# For testing Module-level methods like ActiveFedora.init

describe ActiveFedora do
  
  after :all do
    unstub_rails
    # Restore to default fedora configs
    fedora_config_path = File.join(File.dirname(__FILE__), "..", "..", "config", "fedora.yml")
    ActiveFedora.init(:environment=>"test", :fedora_config_path=>fedora_config_path)
  end
  
  
  describe "initialization methods" do
    
    describe "environment" do
      it "should use config_options[:environment] if set" do
        ActiveFedora.expects(:config_options).at_least_once.returns(:environment=>"ballyhoo")
        ActiveFedora.environment.should eql("ballyhoo")
      end

      it "should use Rails.env if no config_options and Rails.env is set" do
        stub_rails(:env => "bedbugs")
        ActiveFedora.expects(:config_options).at_least_once.returns({})
        ActiveFedora.environment.should eql("bedbugs")
        unstub_rails
      end

      it "should use ENV['environment'] if neither config_options nor Rails.env are set" do
        ENV['environment'] = "wichita"
        ActiveFedora.expects(:config_options).at_least_once.returns({})
        ActiveFedora.environment.should eql("wichita")
        ENV['environment']='test'
      end

      it "should use ENV['RAILS_ENV'] and log a warning if none of the above are set" do
        ENV['environment']=nil
        ENV['RAILS_ENV'] = "rails_env"
        logger.expects(:warn)
        ActiveFedora.expects(:config_options).at_least_once.returns({})
        ActiveFedora.environment.should eql("rails_env")
        ENV['environment']='test'
      end

      it "should be development if none of the above are present" do
        ENV['environment']=nil
        ENV['RAILS_ENV'] = nil
        ActiveFedora.expects(:config_options).at_least_once.returns({})
        ActiveFedora.environment.should == 'development'
        ENV['environment']="test"
      end
    end

    describe "get_config_path(:fedora)" do
      it "should use the config_options[:config_path] if it exists" do
        ActiveFedora.expects(:config_options).at_least_once.returns({:fedora_config_path => "/path/to/fedora.yml"})
        File.expects(:file?).with("/path/to/fedora.yml").returns(true)
        ActiveFedora.get_config_path(:fedora).should eql("/path/to/fedora.yml")
      end

      it "should look in Rails.root/config/fedora.yml if it exists and no fedora_config_path passed in" do
        ActiveFedora.expects(:config_options).at_least_once.returns({})
        stub_rails(:root => "/rails/root")
        File.expects(:file?).with("/rails/root/config/fedora.yml").returns(true)
        ActiveFedora.get_config_path(:fedora).should eql("/rails/root/config/fedora.yml")
        unstub_rails
      end

      it "should look in ./config/fedora.yml if neither rails.root nor :fedora_config_path are set" do
        ActiveFedora.expects(:config_options).at_least_once.returns({})
        Dir.expects(:getwd).at_least_once.returns("/current/working/directory")
        File.expects(:file?).with("/current/working/directory/config/fedora.yml").returns(true)
        ActiveFedora.get_config_path(:fedora).should eql("/current/working/directory/config/fedora.yml")
      end

      it "should return default fedora.yml that ships with active-fedora if none of the above" do
        ActiveFedora.expects(:config_options).at_least_once.returns({})
        Dir.expects(:getwd).at_least_once.returns("/current/working/directory")
        File.expects(:file?).with("/current/working/directory/config/fedora.yml").returns(false)
        File.expects(:file?).with(File.expand_path(File.join(File.dirname("__FILE__"),'config','fedora.yml'))).returns(true)
        logger.expects(:warn).with("Using the default fedora.yml that comes with active-fedora.  If you want to override this, pass the path to fedora.yml to ActiveFedora - ie. ActiveFedora.init(:fedora_config_path => '/path/to/fedora.yml) - or set Rails.root and put fedora.yml into \#{Rails.root}/config.")
        ActiveFedora.get_config_path(:fedora).should eql(File.expand_path(File.join(File.dirname("__FILE__"),'config','fedora.yml')))
      end
    end

    describe "get_config_path(:solr)" do
      it "should return the solr_config_path if set in config_options hash" do
        ActiveFedora.expects(:config_options).at_least_once.returns({:solr_config_path => "/path/to/solr.yml"})
        File.expects(:file?).with("/path/to/solr.yml").returns(true)
        ActiveFedora.get_config_path(:solr).should eql("/path/to/solr.yml")
      end
      
      it "should return the solr.yml file in the same directory as the fedora.yml if it exists" do
        ActiveFedora::Config.any_instance.expects(:path).returns("/path/to/fedora/config/fedora.yml")
        File.expects(:file?).with("/path/to/fedora/config/solr.yml").returns(true)
        ActiveFedora.get_config_path(:solr).should eql("/path/to/fedora/config/solr.yml")
      end
      
      it "should raise an error if there is not a solr.yml in the same directory as the fedora.yml and the fedora.yml has a solr url defined" do
        ActiveFedora.expects(:config_options).at_least_once.returns({})
        ActiveFedora.expects(:fedora_config_path).returns("/path/to/fedora/config/fedora.yml")
        File.expects(:file?).with("/path/to/fedora/config/solr.yml").returns(false)
        ActiveFedora.expects(:fedora_config).returns({"test"=>{"solr"=>{"url"=>"http://some_url"}}})
        lambda { ActiveFedora.get_config_path(:solr) }.should raise_exception
      end

      context "no solr.yml in same directory as fedora.yml and fedora.yml does not contain solr url" do

        before :each do
          ActiveFedora.expects(:config_options).at_least_once.returns({})
          ActiveFedora::Config.any_instance.expects(:path).returns("/path/to/fedora/config/fedora.yml")
          File.expects(:file?).with("/path/to/fedora/config/solr.yml").returns(false)
        end
        after :each do
          unstub_rails
        end

        it "should not raise an error if there is not a solr.yml in the same directory as the fedora.yml and the fedora.yml has a solr url defined and look in rails.root" do
          stub_rails(:root=>"/rails/root")
          File.expects(:file?).with("/rails/root/config/solr.yml").returns(true)
          ActiveFedora.get_config_path(:solr).should eql("/rails/root/config/solr.yml")
        end

        it "should look in ./config/solr.yml if no rails root" do
          Dir.expects(:getwd).at_least_once.returns("/current/working/directory")
          File.expects(:file?).with("/current/working/directory/config/solr.yml").returns(true)
          ActiveFedora.get_config_path(:solr).should eql("/current/working/directory/config/solr.yml")
        end

        it "should return the default solr.yml file that ships with active-fedora if no other option is set" do
          Dir.expects(:getwd).at_least_once.returns("/current/working/directory")
          File.expects(:file?).with("/current/working/directory/config/solr.yml").returns(false)
          File.expects(:file?).with(File.expand_path(File.join(File.dirname("__FILE__"),'config','solr.yml'))).returns(true)
          logger.expects(:warn).with("Using the default solr.yml that comes with active-fedora.  If you want to override this, pass the path to solr.yml to ActiveFedora - ie. ActiveFedora.init(:solr_config_path => '/path/to/solr.yml) - or set Rails.root and put solr.yml into \#{Rails.root}/config.")
          ActiveFedora.get_config_path(:solr).should eql(File.expand_path(File.join(File.dirname("__FILE__"),'config','solr.yml')))
        end
      end

    end


    describe "#determine url" do
      it "should support config['environment']['fedora']['url'] if config_type is fedora" do
        config = {:test=> {:fedora=>{"url"=>"http://fedoraAdmin:fedorAdmin@localhost:8983/fedora"}}}
        ActiveSupport::Deprecation.expects(:warn).with("Using \"fedora\" in the fedora.yml file is no longer supported")
        ActiveFedora.determine_url("fedora",config).should eql("http://localhost:8983/fedora")
      end

      it "should support config['environment']['url'] if config_type is fedora" do
        config = {:test=> {:url=>"http://fedoraAdmin:fedorAdmin@localhost:8983/fedora"}}
        ActiveFedora.determine_url("fedora",config).should eql("http://localhost:8983/fedora")
      end

      it "should call #get_solr_url to determine the solr url if config_type is solr" do
        config = {:test=>{:default => "http://default.solr:8983"}}
        ActiveFedora.expects(:get_solr_url).with(config[:test]).returns("http://default.solr:8983")
        ActiveFedora.determine_url("solr",config).should eql("http://default.solr:8983")
      end
    end

    describe "load_config" do
      it "should load the file specified in solr_config_path" do
        ActiveFedora.expects(:solr_config_path).returns("/path/to/solr.yml")
        File.expects(:open).with("/path/to/solr.yml").returns("development:\n  default:\n    url: http://devsolr:8983\ntest:\n  default:\n    url: http://mysolr:8080")
        ActiveFedora.load_config(:solr).should eql({:url=>"http://mysolr:8080",:development=>{"default"=>{"url"=>"http://devsolr:8983"}}, :test=>{:default=>{"url"=>"http://mysolr:8080"}}})
        ActiveFedora.solr_config.should eql({:url=>"http://mysolr:8080",:development=>{"default"=>{"url"=>"http://devsolr:8983"}}, :test=>{:default=>{"url"=>"http://mysolr:8080"}}})
      end
    end

    describe "load_configs" do
      describe "when config is not loaded" do
        before do
          ActiveFedora.instance_variable_set :@config_loaded, nil
        end
        it "should load the fedora and solr configs" do
          ActiveFedora.expects(:load_config).with(:fedora)
          ActiveFedora.expects(:load_config).with(:solr)
          ActiveFedora.config_loaded?.should be_false
          ActiveFedora.load_configs
          ActiveFedora.config_loaded?.should be_true
        end
      end
      describe "when config is loaded" do
        before do
          ActiveFedora.instance_variable_set :@config_loaded, true
        end
        it "should load the fedora and solr configs" do
          ActiveFedora.expects(:load_config).never
          ActiveFedora.config_loaded?.should be_true
          ActiveFedora.load_configs
          ActiveFedora.config_loaded?.should be_true
        end
      end
    end

    describe "check_fedora_path_for_solr" do
      it "should find the solr.yml file and return it if it exists" do
        ActiveFedora::Config.any_instance.expects(:path).returns("/path/to/fedora/fedora.yml")
        File.expects(:file?).with("/path/to/fedora/solr.yml").returns(true)
        ActiveFedora.check_fedora_path_for_solr.should == "/path/to/fedora/solr.yml"
      end
      it "should return nil if the solr.yml file is not there" do
        ActiveFedora::Config.any_instance.expects(:path).returns("/path/to/fedora/fedora.yml")
        File.expects(:file?).with("/path/to/fedora/solr.yml").returns(false)
        ActiveFedora.check_fedora_path_for_solr.should be_nil
      end
    end
  end



  ###########################
  
  describe "setting the environment and loading configuration" do
    
    before(:all) do
      @fake_rails_root = File.expand_path(File.dirname(__FILE__) + '/../fixtures/rails_root')
    end

    
    after(:all) do
      config_file = File.join(File.dirname(__FILE__), "..", "..", "config", "fedora.yml")
      environment = "test"
      ActiveFedora.init(:environment=>environment, :fedora_config_path=>config_file)
    end
  
    it "can tell its config paths" do
      ActiveFedora.init
      ActiveFedora.should respond_to(:solr_config_path)
    end
    it "loads a config from the current working directory as a second choice" do
      Dir.stubs(:getwd).returns(@fake_rails_root)
      ActiveFedora.init
      ActiveFedora.get_config_path(:fedora).should eql("#{@fake_rails_root}/config/fedora.yml")
      ActiveFedora.solr_config_path.should eql("#{@fake_rails_root}/config/solr.yml")
    end
    it "loads the config that ships with this gem as a last choice" do
      Dir.stubs(:getwd).returns("/fake/path")
      logger.expects(:warn).with("Using the default fedora.yml that comes with active-fedora.  If you want to override this, pass the path to fedora.yml to ActiveFedora - ie. ActiveFedora.init(:fedora_config_path => '/path/to/fedora.yml) - or set Rails.root and put fedora.yml into \#{Rails.root}/config.").twice
      ActiveFedora.init
      expected_config = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config"))
      ActiveFedora.get_config_path(:fedora).should eql(expected_config+'/fedora.yml')
      ActiveFedora.solr_config_path.should eql(expected_config+'/solr.yml')
    end
    it "raises an error if you pass in a string" do
      lambda{ ActiveFedora.init("#{@fake_rails_root}/config/fake_fedora.yml") }.should raise_exception(ArgumentError)
    end
    it "raises an error if you pass in a non-existant config file" do
      lambda{ ActiveFedora.init(:fedora_config_path=>"really_fake_fedora.yml") }.should raise_exception(ActiveFedora::ConfigurationError)
    end
    
    describe "within Rails" do
      before(:all) do        
        stub_rails(:root=>File.dirname(__FILE__) + '/../fixtures/rails_root')
      end

      after(:all) do
        unstub_rails
      end
      
      it "loads a config from Rails.root as a first choice" do
        ActiveFedora.init
        ActiveFedora.get_config_path(:fedora).should eql("#{Rails.root}/config/fedora.yml")
        ActiveFedora.solr_config_path.should eql("#{Rails.root}/config/solr.yml")
      end
      
      it "can tell what environment it is set to run in" do
        stub_rails(:env=>"development")
        ActiveFedora.init
        ActiveFedora.environment.should eql("development")
      end
      
    end
  end
  
  ##########################
  
  describe ".build_predicate_config_path" do
    it "should return the path to the default config/predicate_mappings.yml if no valid path is given" do
      ActiveFedora.send(:build_predicate_config_path, nil).should == default_predicate_mapping_file
    end

    it "should return the path to the default config/predicate_mappings.yml if specified config file not found" do
      File.expects(:exist?).with("/path/to/predicate_mappings.yml").returns(false)
      File.expects(:exist?).with(default_predicate_mapping_file).returns(true)
      ActiveFedora.send(:build_predicate_config_path,"/path/to").should == default_predicate_mapping_file
    end

    it "should return the path to the specified config_path if it exists" do
      File.expects(:exist?).with("/path/to/predicate_mappings.yml").returns(true)
      ActiveFedora.expects(:valid_predicate_mapping?).returns(true)
      ActiveFedora.send(:build_predicate_config_path,"/path/to").should == "/path/to/predicate_mappings.yml"
    end    
  end

  describe ".predicate_config" do
    before do
      ActiveFedora.instance_variable_set :@config_loaded, nil
    end
    it "should return the default mapping if it has not been initialized" do
      ActiveFedora.predicate_config().should == default_predicate_mapping_file
    end
    describe "when the path has been set" do
      before do
        
        ActiveFedora.instance_variable_set :@predicate_config_path, nil
        ActiveFedora::Config.any_instance.expects(:path).returns("/path/to/my/files/fedora.yml")
      end
      it "should return the path that was set at initialization" do
        File.expects(:exist?).with("/path/to/my/files/predicate_mappings.yml").returns(true)
        ActiveFedora.expects(:valid_predicate_mapping?).with("/path/to/my/files/predicate_mappings.yml").returns(true)
        ActiveFedora.predicate_config.should == "/path/to/my/files/predicate_mappings.yml"
      end
    end
  end

  describe ".valid_predicate_mapping" do
    it "should return true if the predicate mapping has the appropriate keys and value types" do
      ActiveFedora.send(:valid_predicate_mapping?,default_predicate_mapping_file).should be_true
    end
    it "should return false if the mapping is missing the :default_namespace" do
      mock_yaml({:default_namespace0=>"my_namespace",:predicate_mapping=>{:key0=>"value0", :key1=>"value1"}},"/path/to/predicate_mappings.yml")
      ActiveFedora.send(:valid_predicate_mapping?,"/path/to/predicate_mappings.yml").should be_false
    end
    it "should return false if the :default_namespace is not a string" do
      mock_yaml({:default_namespace=>{:foo=>"bar"}, :predicate_mapping=>{:key0=>"value0", :key1=>"value1"}},"/path/to/predicate_mappings.yml")
      ActiveFedora.send(:valid_predicate_mapping?,"/path/to/predicate_mappings.yml").should be_false
    end
    it "should return false if the :predicate_mappings key is missing" do
      mock_yaml({:default_namespace=>"a string"},"/path/to/predicate_mappings.yml")
      ActiveFedora.send(:valid_predicate_mapping?,"/path/to/predicate_mappings.yml").should be_false
    end
    it "should return false if the :predicate_mappings key is not a hash" do
      mock_yaml({:default_namespace=>"a string",:predicate_mapping=>"another string"},"/path/to/predicate_mappings.yml")
      ActiveFedora.send(:valid_predicate_mapping?,"/path/to/predicate_mappings.yml").should be_false
    end

  end

  describe ".init" do
    
    after(:all) do
      # Restore to default fedora configs
      ActiveFedora.init(:environment => "test", :fedora_config_path => File.join(File.dirname(__FILE__), "..", "..", "config", "fedora.yml"))
    end

    describe "outside of rails" do
      it "should load the default packaged config/fedora.yml file if no explicit config path is passed" do
        ActiveFedora.init()
        ActiveFedora.config.credentials.should == {:url=> "http://127.0.0.1:8983/fedora-test", :user=>'fedoraAdmin', :password=>'fedoraAdmin'}
      end
      it "should load the passed config if explicit config passed in as a string" do
        ActiveFedora.init(:fedora_config_path=>'./spec/fixtures/rails_root/config/fedora.yml')
        ActiveFedora.config.credentials.should == {:url=> "http://testhost.com:8983/fedora", :user=>'fedoraAdmin', :password=>'fedoraAdmin'}
      end
    end

    describe "within rails" do

      after(:all) do
        unstub_rails
      end

      describe "versions prior to 3.0" do
        describe "with explicit config path passed in" do
          it "should load the specified config path" do
            fedora_config="test:\n  url: http://fedoraAdmin:fedoraAdmin@127.0.0.1:8983/fedora"
            solr_config = "test:\n  default:\n    url: http://foosolr:8983"

            fedora_config_path = File.expand_path(File.join(File.dirname(__FILE__),"../fixtures/rails_root/config/fedora.yml"))
            solr_config_path = File.expand_path(File.join(File.dirname(__FILE__),"../fixtures/rails_root/config/solr.yml"))
            pred_config_path = File.expand_path(File.join(File.dirname(__FILE__),"../fixtures/rails_root/config/predicate_mappings.yml"))
            
            File.stubs(:open).with(fedora_config_path).returns(fedora_config)
            File.stubs(:open).with(solr_config_path).returns(solr_config)


            ActiveSupport::Deprecation.expects(:warn).with("Using \":url\" in the fedora.yml file without :user and :password is no longer supported")
            ActiveFedora.init(:fedora_config_path=>fedora_config_path,:solr_config_path=>solr_config_path)
            ActiveFedora.solr.class.should == ActiveFedora::SolrService
          end
        end

        describe "with no explicit config path" do
          it "should look for the file in the path defined at Rails.root" do
            stub_rails(:root=>File.join(File.dirname(__FILE__),"../fixtures/rails_root"))
            ActiveFedora.init()
            ActiveFedora.config.credentials[:url].should == "http://testhost.com:8983/fedora"
          end
          it "should load the default file if no config is found at Rails.root" do
            stub_rails(:root=>File.join(File.dirname(__FILE__),"../fixtures/bad/path/to/rails_root"))
            ActiveFedora.init()
            ActiveFedora.config.credentials[:url].should == "http://127.0.0.1:8983/fedora-test"
          end
        end
      end
    end
  end
end



def mock_yaml(hash, path)
  mock_file = mock(path.split("/")[-1])
  File.stubs(:exist?).with(path).returns(true)
  File.expects(:open).with(path).returns(mock_file)
  YAML.expects(:load).returns(hash)
end

def default_predicate_mapping_file
  File.expand_path(File.join(File.dirname(__FILE__),"..","..","config","predicate_mappings.yml"))
end

def stub_rails(opts={})
  Object.const_set("Rails",Class)
  Rails.send(:undef_method,:env) if Rails.respond_to?(:env)
  Rails.send(:undef_method,:root) if Rails.respond_to?(:root)
  opts.each { |k,v| Rails.send(:define_method,k){ return v } }
end

def unstub_rails
  Object.send(:remove_const,:Rails) if defined?(Rails)
end
    

def setup_pretest_env
  ENV['RAILS_ENV']='test'
  ENV['environment']='test'
end

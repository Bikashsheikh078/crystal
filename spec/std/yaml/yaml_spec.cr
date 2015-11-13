require "spec"
require "yaml"

describe "YAML" do
  describe "parser" do
    assert { YAML.load("foo").should eq("foo") }
    assert { YAML.load("- foo\n- bar").should eq(["foo", "bar"]) }
    assert { YAML.load_all("---\nfoo\n---\nbar\n").should eq(["foo", "bar"]) }
    assert { YAML.load("foo: bar").should eq({"foo" => "bar"}) }
    assert { YAML.load("--- []\n").should eq([] of YAML::Type) }
    assert { YAML.load("---\n...").should eq("") }

    it "parses recursive sequence" do
      doc = YAML.load("--- &foo\n- *foo\n") as Array
      doc[0].should be(doc)
    end

    it "parses recursive mapping" do
      doc = YAML.load(%(--- &1
        friends:
        - *1
        )) as Hash
      (doc["friends"] as Array)[0].should be(doc)
    end

    it "parses alias to scalar" do
      doc = YAML.load("---\n- &x foo\n- *x\n") as Array
      doc.should eq(["foo", "foo"])
      doc[0].should be(doc[1])
    end

    describe "merging with << key" do
      it "merges other mapping" do
        doc = YAML.load(%(---
          foo: bar
          <<:
            baz: foobar
          )) as Hash
        doc["baz"]?.should eq("foobar")
      end

      it "raises if merging with missing alias" do
        expect_raises do
          YAML.load(%(---
            foo:
              <<: *bar
          ))
        end
      end

      it "doesn't merge explicit string key <<" do
        doc = YAML.load(%(---
          foo: &foo
            hello: world
          bar:
            !!str '<<': *foo
        ))
        doc.should eq({"foo": {"hello": "world"}, "bar": {"<<": {"hello": "world"}}})
      end

      it "doesn't merge empty mapping" do
        doc = YAML.load(%(---
          foo: &foo
          bar:
            <<: *foo
        )) as Hash
        doc["bar"].should eq({"<<": ""})
      end

      it "doesn't merge arrays" do
        doc = YAML.load(%(---
          foo: &foo
            - 1
          bar:
            <<: *foo
        )) as Hash
        doc["bar"].should eq({"<<": ["1"]})
      end
    end
  end

  describe "dump" do
    it "returns YAML as a string" do
      YAML.dump(%w(1 2 3)).should eq("--- \n- 1\n- 2\n- 3")
    end

    it "writes YAML to a stream" do
      string = String.build do |str|
        YAML.dump(%w(1 2 3), str)
      end
      string.should eq("--- \n- 1\n- 2\n- 3")
    end
  end
end

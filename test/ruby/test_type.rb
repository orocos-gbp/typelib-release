require 'set'
require './test_config'
require 'typelib'
require 'test/unit'
require BUILDDIR + '/ruby/libtest_ruby'
require 'pp'

class TC_Type < Test::Unit::TestCase
    include Typelib
    def teardown
	GC.start
    end

    # Not in setup() since we want to make sure
    # that the registry is not destroyed by the GC
    def make_registry
        registry = Registry.new
        testfile = File.join(SRCDIR, "test_cimport.1")
        assert_raises(RuntimeError) { registry.import( testfile  ) }
        registry.import( testfile, "c" )

        registry
    end

    def test_type_should_be_equal_when_they_are_the_same_object
        type = CXXRegistry.new.get("/int32_t")
        assert_equal type, type
    end

    def test_type_should_be_equal_when_they_are_the_same_definition
        type0 = CXXRegistry.new.get("/int32_t")
        type1 = CXXRegistry.new.get("/int32_t")
        assert_equal type0, type1
    end

    def test_type_can_compare_itself_to_an_arbitrary_object
        type = CXXRegistry.new.get("/int32_t")
        assert !(type == Object.new)
    end

    def test_base_type_classes_can_be_compared
        assert(Typelib::CompoundType == Typelib::CompoundType)
        assert(Typelib::CompoundType != Object.new)
    end

    def test_casts_to
        r0 = make_registry
        r1 = make_registry
        t0 = r0.get 'StdCollections'
        t1 = r1.get 'StdCollections'
        wrong_type = r1.get 'A'
        assert t0.casts_to?(t1)
        assert !t0.casts_to?(wrong_type)
    end


    def test_type_names
	registry = make_registry
	bla = registry.get "/NS1/Bla/Test"
	assert_equal("/NS1/Bla/Test", bla.name)
	assert_equal("Test", bla.basename)
	assert_equal("/NS1/Bla/", bla.namespace)
	assert_equal("::NS1::Bla::", bla.namespace('::'))
	assert_equal("/NS1/Bla/Test", bla.full_name)
	assert_equal("::NS1::Bla::Test", bla.full_name('::'))
	assert_equal("NS1/Bla/Test", bla.full_name(Typelib::NAMESPACE_SEPARATOR, true))
	assert_equal("NS1::Bla::Test", bla.full_name('::', true))

        test_data = "<typelib><opaque name=\"/Bla/Blo&lt;/Template&lt;/Inside&gt;&gt;\" size=\"0\" /></typelib>"
        registry = Registry.from_xml(test_data)
        type     = registry.get("/Bla/Blo</Template</Inside>>")
        assert_equal("/Bla/", type.namespace)
        assert_equal("Blo</Template</Inside>>", type.basename)
        assert_equal("::Bla::Blo<::Template<::Inside>>", type.full_name("::", false))
    end

    def test_pointer
        type = CXXRegistry.new.build("/int*")
        assert_not_equal(type, type.deference)
        assert_not_equal(type, type.to_ptr)
        assert_not_equal(type.to_ptr, type.deference)
        assert_equal(type, type.deference.to_ptr)
        assert_equal(type, type.to_ptr.deference)
    end

    def test_memory_layout
        reg = make_registry
        std = reg.get("StdCollections")
        off_dlb_vector = std.offset_of("dbl_vector")
        off_v8 = std.offset_of("v8")
        off_v_of_v = std.offset_of("v_of_v")

        layout = std.memory_layout
        expected = [:FLAG_MEMCPY, off_dlb_vector,
            :FLAG_CONTAINER, reg.get("/std/vector</double>"),
                :FLAG_MEMCPY, 8,
            :FLAG_END,
            :FLAG_MEMCPY, off_v_of_v - off_v8,
            :FLAG_CONTAINER, reg.get("/std/vector</std/vector</double>>"),
                :FLAG_CONTAINER, reg.get("/std/vector</double>"),
                    :FLAG_MEMCPY, 8,
                :FLAG_END,
            :FLAG_END,
            :FLAG_MEMCPY, 17]

        assert_equal(expected, layout)
    end
end



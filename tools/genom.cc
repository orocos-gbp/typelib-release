#include "genom.hh"

#include <iostream>

#include "genommodule.hh"
#include "preprocess.hh"

#include "configset.hh"

#include <boost/tokenizer.hpp>

using namespace std;
using namespace boost;
using Typelib::Registry;

GenomPlugin::GenomPlugin()
    : Plugin("genom", "import") {}

list<string> GenomPlugin::getOptions() const
{
    static const char* arguments[] = 
    { ":include,I=string:include search path" };
    return list<string>(arguments, arguments + 1);
}

bool GenomPlugin::apply(const OptionList& remaining, const ConfigSet& options, Registry* registry)
{
    if (remaining.empty())
    {
        cerr << "No file found on command line. Aborting" << endl;
        return false;
    }

    list<string> cppargs;
    
    string includes = options.getString("include");
    if (! includes.empty())
    {
        // split at ':'
        
        typedef tokenizer< char_separator<char> >  Splitter;
        Splitter splitter(includes, char_separator<char> (":"));
        for (Splitter::const_iterator it = splitter.begin(); it != splitter.end(); ++it)
            cppargs.push_back("-I" + *it);
    }

    string file   = remaining.front();
    string i_file = preprocess(file, cppargs);
    if (i_file.empty())
    {
        cerr << "Could not preprocess " << file << ", aborting" << endl;
        return false;
    }


    try
    {
        GenomModule reader(registry);
        int old_count = registry -> getCount();

        reader.read(i_file);
        cout << "Found " << registry -> getCount() - old_count << " types in " << file << endl;
        return true;
    }
    catch(Typelib::RegistryException& e)
    {
        cerr << "Error in type management: " << e.toString() << endl;
        return false;
    }
    catch(std::exception& e)
    {
        cerr << "Error parsing file " << file << ":\n\t"
            << typeid(e).name() << endl;
        return false;
    }
}


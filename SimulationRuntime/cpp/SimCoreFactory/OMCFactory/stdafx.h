// stdafx.h :
//

#pragma once
#ifndef BOOST_THREAD_USE_DLL
#define BOOST_THREAD_USE_DLL
#endif
#ifndef BOOST_ALL_DYN_LINK
#define BOOST_ALL_DYN_LINK
#endif

#define WIN32_LEAN_AND_MEAN


#include <vector>
#include <map>
#include <string>
#include <ostream>                  // Use stream for output

#include <boost/ref.hpp>
#include <boost/bind.hpp>
//vxworks  #include <boost/function.hpp>
#define BOOST_UBLAS_SHALLOW_ARRAY_ADAPTOR
#include <boost/numeric/ublas/storage.hpp>
#include <boost/numeric/ublas/vector.hpp>
#include <boost/numeric/ublas/io.hpp>
#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/matrix_proxy.hpp>
#include <boost/numeric/ublas/matrix_sparse.hpp>
#include <boost/numeric/ublas/vector.hpp>
#include <boost/numeric/ublas/io.hpp>
#include <boost/serialization/nvp.hpp>
#include <boost/tuple/tuple.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/weak_ptr.hpp>
//vxworks #include <boost/algorithm/string.hpp>
#include <boost/foreach.hpp>
#include <boost/unordered_map.hpp>
#include <boost/any.hpp>
#include <boost/range/adaptor/map.hpp>
#include <boost/range/algorithm/copy.hpp>
#include <boost/math/tools/real_cast.hpp>
#include <boost/program_options.hpp>
#include <boost/assign/list_of.hpp>
#include <boost/numeric/ublas/matrix_sparse.hpp>
namespace uBlas = boost::numeric::ublas;
using std::vector;
using std::map;
using std::string;
using std::string;
using std::ostream;
using  boost::tuple;
using  boost::tie;
using namespace boost::numeric;
using namespace std;
using boost::shared_ptr;
using boost::weak_ptr;
using boost::get;
using boost::unordered_map;
using namespace boost::assign; // bring 'map_list_of()' into scope
typedef ublas::shallow_array_adaptor<double> adaptor_t;
typedef ublas::vector<double, adaptor_t> shared_vector_t;
typedef ublas::matrix<double, adaptor_t> shared_matrix_t;


#include <Policies/FactoryConfig.h>












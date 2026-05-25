const String baseUrl = 'https://localhost:7194/api/';

const String loginEndpoint = '${baseUrl}auth/login';
const String currentUserEndpoint = '${baseUrl}user/me';
const String getAllUsersEndpoint = '${baseUrl}user/get';
const String addUserEndpoint = '${baseUrl}user/add';

String updateUserEndpoint(int id) => '${baseUrl}user/update/$id';
String deleteUserEndpoint(int id) => '${baseUrl}user/delete/$id';

// Category
const String categoryGetEndpoint = '${baseUrl}category/Get';
const String categoryAddEndpoint = '${baseUrl}category/Add';
String categoryUpdateEndpoint(int id) => '${baseUrl}category/Update/$id';
String categoryDeleteEndpoint(int id) => '${baseUrl}category/Delete/$id';

// Unit
const String unitGetEndpoint = '${baseUrl}unit/Get';
const String unitAddEndpoint = '${baseUrl}unit/Add';
String unitUpdateEndpoint(int id) => '${baseUrl}unit/Update/$id';
String unitDeleteEndpoint(int id) => '${baseUrl}unit/Delete/$id';

// Product
const String productGetEndpoint = '${baseUrl}product/Get';
const String productAddEndpoint = '${baseUrl}product/Add';
String productUpdateEndpoint(int id) => '${baseUrl}product/Update/$id';
String productDeleteEndpoint(int id) => '${baseUrl}product/Delete/$id';

// Stock (inventory batches)
const String stockGetEndpoint = '${baseUrl}stock/get';
const String stockAddEndpoint = '${baseUrl}stock/add';

// Customer
const String customerGetEndpoint = '${baseUrl}customer/get';
const String customerAddEndpoint = '${baseUrl}customer/add';

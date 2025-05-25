# Sistema-de-trazabilidad-basado-en-tecnologia-blockchain

Este código es un prototipo de token basado en el ERC1155, para realizar la trazabilidad de productos a lo largo de la cadena de producción. El objetivo de este token es relacionar todos los productos o procesos implicados en la producción, dando como resultado un grafo dirigido aciclico. Esta estructura de grafo permite que desde cualquiera de los nodos se puedan realizar una trazabilidad completa del producto en cualquiera de las direcciones. 

El codigo contiene 3 categorías de funciones que se pueden emplear y aparecen explicadas a continuación:

## Funciones de usuario
Estas funciones gestionan los usuarios participantes en el sistema. Estas funciones solo son ejecutables por parte del administrador del sistema.

### addUser
Esta función le permite al administrador añadir usuarios al sistema. Esto permite que los usuarios añadidos puedan ejecutar otras funciones en el sistema

### deleteUser
Esta función permite al administrador eliminar usuarios del sistema, evitando así que pueden siguir ejecutando funciones dentro de este.

## Funciones de categoría
Estas funciones son las encargadas de crear el grafo de categorías que funciona como el "blueprint" para la creación del grafo de productos.

### createCategory
Función encargada de crear las categorias, es decir los nodos participantes en el grafo de categorias.

### addCategory 
Función que permite relacionar dos categorías, es decir crear una arista entre dos nodos en el grafo de categorías.

### getCategory
Esta función permite ver la información relacionada con la categoría introducida. Muestra un array de padres, un array de hijos, el bitmap de predecesores y el nombre de la categoria.

## Funciones de producto
Estas funciones son las encargadas de la gestión de los productos. Con estas funciones se gestiona el grafo de productos, que es lo que al final proporcionará la trazabilidad del producto.

### createToken
Esta función es la encarga de generar los nodos que se emplearán en el grafo de productos. Genera tokens que identifican de manera única cada producto y a su dueño. Estos tokens serán los nodos del grafo de productos.

### deleteProduct
Esta función es la encargada de marcar los productos como inactivos, es decir, indicar que no son usables. Los productos no se eliminan completamente 

### getProduct 
Esta función muestra la toda información relativa a al producto indicado. 

### joinProduct
Esta función es la encargada de realacionar dos productos entre sí, es decir crear una arista entre los dos tokens en el grafo de productos.

### replaceProduct
Esta función permite incorporar un recambio de un producto dañado al grafo de productos, indicando por qué producto se intercambia, pero manteniendo a ambos en el grafo.

### addOn
Esta función permite añadir productos al grafo, aunque este grafo ya esté finalizado. 



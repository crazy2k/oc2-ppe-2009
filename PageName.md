# Idioteces para el informe #

## page\_alloc ##

Si quedan paginas fiscas disponibles, caso contrario devuelve un codigo de error, 'page\_alloc' se obtiene la primera pagina de la lista page\_free\_list, haciendo uso de la conveniente macro LIST\_FIRST, y luego se la elimina de la lista mediadiante una llamada a LIST\_REMOVE.
Luego la direccion de memoria de la pagina obtenida se guarda en el variable refenciada por el parametro pp\_store.


## page\_free ##

Esta funcion vuelve a ubicar la pagina 'pp', en la lista 'page\_free\_list', simplemente llamando a la macro LIST\_INSERT\_HEAD, que ubica a la pagina al principio de la lista.


# pgdir\_walk #

Como se usa un modelo flat para la segmentacion la direccion linea de 'va' es identica a la virtual.
De forma que pueden obtenerse los indices sobre el directorio y la tabla de paginas utilizando directamente las macros PDX y PTX sobre 'va'.
El primer paso es obtener la entrada del directorio correspondiente a la tabla de paginas pertinentes, la cual se obtiene facilmente direccionando sobre pgdir, y utilizando PDX(va), como indice.

Luego si la tabla de paginas estaba presente, simplemente direccionamos sobre la misma utilizando, PTX(va), y guardamos un puntero a la entry obtenida en pte\_store.

Si la tabla no esta presente, devolvemos un error; a menos q el parametro 'create' sea igual a 1. En tal caso procedemos a reservar memoria fisica para la misma.

Como primer paso obtenemos una pagina libre llamando a la funcion page\_alloc, si esta no posee mas memoria disponible, retornamos error.
Si la llamada tiene exito, obtenemos su direccion fisica mediante, page2pa. Y escribimos en la entry del directorio obtenida anteriormente; cual es la direccion fisica correspondiente, y que los campos presente (P) y de escritura (W) estan activos.
Finalmente usando esta direccion fisica, calculamos su direccion virtual mediante KADDR, y le sumamos el valor de PTX(va), para obtener la direccion virtual del entry en la pagina de tablas. Valor q luego se guarda en pte\_store.
Por ultimo seteamos en 0 todos los bytes de la tabla, mediante memset, indicando que ninguna de las paginas de la misma se encuentra presente en memoria fisica.


# page\_insert #

page\_insert mapea una direccion virtual, a una pagina fisica de la memoria principal.

El procedimiente que se sigue es el siguiente:

Primero obtiene el entry correspondiente a la direccion virtual especificada en 'va', mediante una llamada a pgdir\_walk, si esta no finaliza satisfactoriamente, la funcion retorna con un error.

A continuacion revisa si el entry de la tabla de paginas, para esa 'va', se encuentra ya configurada para una pagina fisica presente.
Si esto es asi, revisa q la pagina q estaba presente no sea la misma que la que se esta agregando, y en caso de ser una diferente la libera invocando a page\_remove. Esto sea hace comparando la direccion fisica de la pagina q se quiere mapear (resultado de pagetopa()), con la que estaba presente.

Luego para todos los casos donde la pagina que se agrega no era la misma que estaba ya presente se incrementa el contador de referencias de la misma en 1.

Finalemente, se escribe en el entry correspondiente a la tabla de paginas para esa direccion vitual, la direccion fisica de la pagina nueva, y se activan los bits de presente y los especificados en el parametro 'perm'.


## page\_lookup ##

Esta funcion obtiene la estructura de pagina, correspondiente a la pagina fisica mapeada con la direccion virtual especificada en 'va'.
En el caso de que el parametro pte\_store sea distinto de 0, (cuando se invoca la funcion desde remove), se guarda en este parametro, un puntero al entry de la tabla de paginas, donde estaba mapeada la pagina.

Se obtiene la direccion fisica de la pagina, simplemente llamando a 'pgdir\_walk', y mediante una llamada a 'pa2page', se obtiene la estructura de la misma, a partir de su direccion fisica. Esta se encuentra en los primeros 20 bits, del puntero a entry de pagina, que devuelve 'pgdir\_walk' por el parametro pte\_store. Este valor es el devuelto por la funcion.

Cuando el valor de pte\_store es 0, se le asigna a esta variable un puntero a una variable local, para poder llamar a 'pgdir\_walk', sin que esta genere errores.

En el caso de q la funcion 'pgdir\_walk', retorne un codigo de error, page\_lookup devuelve 0.


## page\_remove ##

Esta funcion llama a 'page\_lookup', para obtener la estructura de la pagina correspondiente a la direccion virtual especificada en 'va'.

Revisa el entry de la misma, obtindo en 'page\_lookup', y si el bit presente, se encuetra activo. Setea el valor del entry obtenido en 0 (indicando q esa direccion virtual ya no posee soporte fisico). Y llama a 'page\_decref', la cual descuenta en uno el valor del contador y si esta alcanza el 0, vuelve a colocar la pagina en la lista de paginas libres.

Por ultimo invalida el TBL (translation lookaside buffer), debido a que ya no hay ninguna pagina fisica que corresponda con 'va'.
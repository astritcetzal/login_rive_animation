# login_rive_animation

Aplicación Flutter con inicio de sesión en Firebase, animación Rive y consumo de la API de Spring Boot del proyecto Market.

Este documento describe las funcionalidades agregadas, cómo funcionan y cómo probarlas.

---

## 1. Requisitos para ejecutar

- Flutter configurado en el equipo.
- Backend de Spring Boot ejecutándose en el puerto **8090**.
- Base de datos con la que trabaja ese backend disponible.
- Usuario válido en Firebase para iniciar sesión.

La aplicación usa esta URL base en las pantallas de productos y compras:

```text
http://localhost:8090
```

Ese valor está en:

- `lib/screens/products_screen.dart`
- `lib/screens/purchases_screen.dart`

Si se ejecuta en un emulador de Android, hay que cambiarlo por:

```text
http://10.0.2.2:8090
```

Si se ejecuta en un celular físico, hay que usar la IP de la computadora en la red local, por ejemplo:

```text
http://192.168.1.X:8090
```

---

## 2. Categoría visible en cada producto

**Archivo:** `lib/screens/products_screen.dart`

Antes la lista mostraba nombre, stock y precio. Ahora también muestra la categoría de cada producto.

La categoría se obtiene del objeto anidado que envía el backend:

```dart
product['category']['category']
```

En el código se lee con una comprobación para evitar errores si el producto no trae categoría:

```dart
String _categoryName(dynamic product) {
  final category = product['category'];

  if (category is Map && category['category'] != null) {
    return category['category'].toString();
  }
  return 'Sin categoría';
}
```

Cada producto se muestra en una tarjeta con:

- Una letra inicial dentro de un círculo.
- El nombre del producto.
- `Categoría: <nombre de la categoría>`.
- `Stock: <cantidad>`.
- El precio a la derecha.

Comportamiento:

- Si el backend envía `category: { category: "..." }`, se muestra ese texto.
- Si el producto no trae categoría o viene vacía, se muestra **“Sin categoría”**.
- El precio se muestra tal como llega de la API, con el formato `$<valor>`; no se redondea ni se convierte a otro formato.

La API de productos del backend devuelve, por ejemplo, esta categoría real:

```json
"category": {
  "active": true,
  "category": "Frutas y verduras",
  "categoryId": 1
}
```

Por lo tanto, con el backend actual y el código nuevo, el producto debe mostrar `Categoría: Frutas y verduras`.

---

## 3. Botón “Cerrar sesión”

**Archivo:** `lib/screens/products_screen.dart`

Se agregó un botón visible en la barra superior de la pantalla de productos. Tiene el ícono de salida y el texto **“Cerrar sesión”**.

Qué hace al presionarlo:

1. Ejecuta `FirebaseAuth.instance.signOut()`.
2. Espera a que termine el cierre de sesión.
3. Regresa a la pantalla de Login.
4. Borra el historial de navegación, para que el usuario no pueda volver a Productos con el botón “atrás”.

Código que lo realiza:

```dart
Future<void> _logout() async {
  await FirebaseAuth.instance.signOut();

  if (!mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}
```

Qué no hace:

- No elimina datos de la base de datos.
- No llama a un endpoint del backend para cerrar sesión.
- No elimina la cuenta del usuario.

Solo cierra la sesión de Firebase en la app y vuelve al Login.

---

## 4. Pantalla amigable de error con botón “Reintentar”

**Archivo nuevo:** `lib/widgets/error_view.dart`

Antes, cuando fallaba la conexión, la pantalla mostraba un texto técnico como:

```text
Error: Exception: ...
```

Ahora se muestra una pantalla con:

- Un ícono de nube desconectada.
- El título **“¡Ups! Algo salió mal”**.
- Un mensaje explicando que no se pudo cargar la información.
- Un botón **“Reintentar”** con ícono de refrescar.

Se usa en:

- La pantalla de productos.
- La pantalla de compras.

Cómo funciona el botón “Reintentar”:

1. Vuelve a ejecutar la petición al servidor.
2. Mientras responde, se muestra el indicador de carga.
3. Si ahora responde bien, se muestra la lista.
4. Si vuelve a fallar, se vuelve a mostrar la pantalla de error.

Mensajes de error:

- Productos: “No pudimos cargar los productos. Verifica que el servidor esté encendido.”
- Compras: “No pudimos cargar las compras. Verifica que el servidor esté encendido.”

Diferencia entre error y lista vacía:

- **Error:** el servidor no respondió o respondió con un problema. Se muestra la pantalla con “Reintentar”.
- **Lista vacía:** el servidor respondió correctamente, pero no hay registros:
  - Productos: **“No hay productos disponibles”**.
  - Compras: **“Todavía no hay compras registradas”**.

---

## 5. Nueva pantalla de compras

**Archivo nuevo:** `lib/screens/purchases_screen.dart`

Esta pantalla consume el listado de compras y lo muestra en tarjetas.

### Cómo se llega a ella

Desde la pantalla de Productos, en la barra superior hay un ícono de bolsa de compras con la descripción **“Ver compras”**. Al tocarlo se abre la pantalla **“Compras registradas”**.

### Petición que realiza

Primero llama a:

```text
GET http://localhost:8090/purchases/all
```

Si el servidor responde **404**, intenta automáticamente con la ruta que ya existía en el backend:

```text
GET http://localhost:8090/purchase/
```

Esto permite que la pantalla funcione con las dos versiones del backend.

Si la respuesta es correcta, se lee la lista de compras. Si no, se muestra la pantalla de error con “Reintentar”.

### Qué muestra cada tarjeta de compra

Cada compra aparece en una tarjeta con:

- **Compra #**: el `purchaseId`. Si viene vacío, se muestra `s/n`.
- **Total**: la suma de los totales de los artículos de esa compra.
- **Cliente**: el `clientId`.
- **Fecha**: se muestra como `dd/MM/aaaa hh:mm`. Si la fecha no se puede interpretar, se muestra **“Sin fecha”**.
- **Pago**: el valor de `paymentMethod` tal como lo envía el backend.
- **Artículos**: la cantidad de elementos dentro de `items`.
- **Estado**: el valor de `state` tal como lo envía el backend.
- **Comentario**: solo aparece si el campo `comment` tiene texto.

Detalles del cálculo:

- El total no viene de un campo del backend. Se calcula sumando el campo `total` de cada artículo.
- Si un artículo no trae `total`, suma `0`.
- Si la compra no trae artículos, el total se muestra como `$0.00`.
- La cantidad de artículos es el número de elementos de `items`; si no hay lista, es `0`.

Importante sobre Pago y Estado:

La pantalla no traduce los valores. Si el backend envía `"E"` como método de pago, se muestra `"E"`. Si envía `"P"` como estado, se muestra `"P"`. No se inventaron equivalencias como “Efectivo” o “Pagado”.

### Otras funciones de la pantalla

- Indicador de carga mientras responde el servidor.
- Botón de actualizar en la barra superior, con ícono de refrescar y descripción **“Actualizar”**.
- Estado vacío si no hay compras registradas.
- Pantalla de error con “Reintentar” si falla la petición.

---

## 6. Cómo acceder a GET /purchases/all

El endpoint está definido en el controlador de compras del backend:

```java
@RequestMapping({"/purchase", "/purchases"})

@GetMapping({"/", "/all"})
```

Con ese mapeo, el listado de compras responde en:

- `http://localhost:8090/purchase/`
- `http://localhost:8090/purchase/all`
- `http://localhost:8090/purchases/`
- `http://localhost:8090/purchases/all`

**Muy importante:** el backend que estaba ejecutándose fue iniciado antes de este cambio, por lo que todavía tiene cargada la ruta anterior. Para que `/purchases/all` funcione hay que **detener y volver a ejecutar el backend** desde IntelliJ o desde la terminal.

El cambio ya está aplicado en el clon que se ejecuta desde IntelliJ:

```text
C:\Users\cetza\Programacion_aplicada\market-backend-2026-3-a\market-backend-2026-3-a
```

y también en el worktree del backend:

```text
C:\Users\cetza\.local\share\opencode\worktree\a7d64a\c-users-cetza-actividades-escuela-movile-login-rive-animation
```

Después de reiniciar el backend, se puede acceder de estas formas:

### Desde el navegador

Abrir:

```text
http://localhost:8090/purchases/all
```

Se mostrará el JSON con la lista de compras.

### Desde PowerShell

```powershell
Invoke-RestMethod http://localhost:8090/purchases/all | ConvertTo-Json -Depth 6
```

### Desde Swagger UI

1. Abrir:

```text
http://localhost:8090/swagger-ui/index.html
```

2. Buscar la sección **Purchase**.
3. Localizar la operación **Get all purchases**.
4. Presionar **Try it out**.
5. Presionar **Execute**.

Swagger UI respondió correctamente en esta dirección cuando se revisó el backend:

```text
http://localhost:8090/swagger-ui/index.html  ->  200
```

### Desde Postman

- Método: `GET`
- URL: `http://localhost:8090/purchases/all`
- Sin cuerpo ni parámetros.

### Si todavía responde 404

Significa que el backend en ejecución sigue siendo el anterior. Hay que reiniciarlo. Mientras tanto, la pantalla de Flutter usa automáticamente `/purchase/`, que sí responde:

```text
http://localhost:8090/purchase/  ->  200
```

---

## 7. Estructura de una compra devuelta por la API

Cada elemento de la lista contiene estos campos, tomados de la respuesta real del backend:

- `purchaseId`
- `clientId`
- `date`
- `paymentMethod`
- `comment`
- `state`
- `items`
  - `productId`
  - `amount`
  - `total`
  - `active`

Ejemplo de valores reales observados:

```text
purchaseId: 1
clientId: "4546221"
date: "1992-08-10T17:30:00"
paymentMethod: "E"
state: "P"
items: 5 artículos
```

La pantalla suma los `total` de los artículos para mostrar el total de la compra.

---

## 8. Cómo probar la aplicación

1. Enciende el backend en el puerto **8090**.
2. Si acabas de aplicar el cambio de `/purchases/all`, reinicia el backend.
3. Ejecuta la app Flutter con `flutter run` o desde tu IDE.
4. Inicia sesión con un usuario válido de Firebase.
5. En Productos verifica que aparezca la categoría de cada producto.
6. Toca el ícono de bolsa para abrir **“Compras registradas”**.
7. Usa el botón de actualizar si quieres volver a consultar.
8. Toca **“Cerrar sesión”** y confirma que regresas al Login.

---

## 9. Solución de problemas

### No veo el botón de cerrar sesión ni la categoría

El código nuevo sí está en:

- `lib/screens/products_screen.dart`
- `lib/screens/purchases_screen.dart`
- `lib/widgets/error_view.dart`

Si la app sigue mostrando la versión anterior:

1. Confirma que abriste el proyecto correcto:

   ```text
   C:\Users\cetza\actividades-escuela\Movile\login_rive_animation
   ```

   La carpeta `login_rive_animation_26_a_2026` es otro proyecto distinto y solo contiene una pantalla “Hello World!”.

2. Detén la app y vuelve a ejecutarla. No basta con recargar en caliente, porque la pantalla de Productos cambió de `StatelessWidget` a `StatefulWidget`. Se necesita un reinicio completo de la app o una recarga en caliente completa (`R` en la terminal de Flutter).

3. Si estás usando una versión instalada en el emulador o teléfono, vuelve a compilar e instalar.

### Aparece “Sin categoría”

Revisa la respuesta de la API:

```powershell
Invoke-RestMethod http://localhost:8090/products | Select-Object -First 1 | ConvertTo-Json -Depth 5
```

Si el campo `category` viene vacío o no viene, la app muestra “Sin categoría”. Con la base de datos revisada, la API sí devuelve la categoría.

### GET /purchases/all responde 404

El backend no se ha reiniciado después del cambio. Detén el proceso y vuelve a ejecutarlo. La app seguirá funcionando mediante `/purchase/` mientras tanto.

### La app muestra la pantalla de error

Verifica que:

- El backend esté encendido en el puerto 8090.
- La URL base sea correcta para tu dispositivo.
- La base de datos esté disponible.

---

## 10. Archivos modificados y nuevos

**Flutter:**

- Modificado: `lib/screens/products_screen.dart`
- Nuevo: `lib/screens/purchases_screen.dart`
- Nuevo: `lib/widgets/error_view.dart`
- Documentación: `README.md`

**Backend:**

- `PurchaseController.java`: se agregó el alias `/purchases/all` en:
  - El clon de `C:\Users\cetza\Programacion_aplicada\market-backend-2026-3-a\market-backend-2026-3-a`.
  - El worktree del backend usado en esta sesión.

No se modificaron `login_screen.dart`, `main.dart`, la animación Rive ni la configuración de Firebase.

---

## 11. Verificación realizada

- `flutter analyze` terminó con **“No issues found!”**.
- El backend compiló correctamente con `gradlew compileJava`.
- Se consultaron con el backend en ejecución:
  - `GET /products` -> 200, con categoría incluida.
  - `GET /purchase/` -> 200, con compras y artículos.
  - `GET /swagger-ui/index.html` -> 200.
- Antes de reiniciar el backend, `GET /purchases/all` devolvía 404 porque el proceso en ejecución tenía la versión anterior del controlador.
- No se ejecutó la app contra Firebase en un dispositivo para verificar visualmente la interfaz en esta revisión.

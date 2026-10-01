# Sudoku

Un Sudoku nativo para Mac, sin anuncios, escrito en SwiftUI.

Nació como una forma práctica de aprender Swift y los frameworks de Apple, así que el código
prefiere APIs modernas e idiomáticas (`@Observable`, Swift Testing, concurrencia de Swift,
SwiftData) y explica *por qué* hace las cosas como las hace.

*[Read in English](README.md)*

## ¿Solo quieres jugar?

No necesitas saber nada de programación. Solo necesitas un Mac con **macOS 27 o posterior**.

### 1. Descárgalo

1. Entra en la [última versión](https://github.com/vg0904/Sudoku/releases/latest).
2. En **Assets**, haz clic en **Sudoku.zip**. Se guarda en tu carpeta **Descargas**.
3. Abre **Descargas** y haz doble clic en **Sudoku.zip**. Aparece la app **Sudoku** al lado.
4. Arrastra **Sudoku** a tu carpeta **Aplicaciones**.

### 2. Ábrelo por primera vez

Como Sudoku es un proyecto gratuito y no está registrado con Apple
([aquí explico por qué](#sobre-este-proyecto)), la primera vez que lo abras tu Mac mostrará un aviso
diciendo que no puede comprobar la app. Es normal. Solo hay que permitirla **una vez**:

1. Haz doble clic en **Sudoku** dentro de Aplicaciones. Cuando aparezca el aviso, ciérralo con el
   botón de aceptar (no con el de mover a la papelera).
2. Abre **Ajustes del Sistema** (el icono gris de engranaje del Dock, o  → Ajustes del Sistema).
3. En la barra lateral, haz clic en **Privacidad y seguridad**.
4. Baja hasta la sección **Seguridad**. Verás un mensaje sobre Sudoku: haz clic en
   **Abrir igualmente** y escribe la contraseña de tu Mac o usa Touch ID.
5. Haz clic en **Abrir**.

Listo. A partir de ahora, Sudoku se abre como cualquier otra app.

### 3. Juega

- **Haz clic en una celda** y **escribe un número** con el teclado, o haz clic en uno del teclado
  numérico de abajo. También puedes moverte con las flechas.
- Cada fila, cada columna y cada recuadro de 3×3 debe tener todos los números del 1 al 9, sin
  repetir ninguno.
- Un número equivocado se pone en rojo y te quita un corazón ♥. Selecciónalo y pulsa **Borrar** (⌫)
  para quitarlo.
- El teclado numérico muestra cuántos llevas de cada número; una ✓ indica que ya están los nueve.
- La app abre con un menú de inicio: elige **Continuar** para seguir tu última partida, o elige una
  dificultad y pulsa **Nueva partida**.
- Pulsa ⌘P para pausar. La partida se guarda al cerrar la app o al volver al menú (el botón 🏠 o ⇧⌘M), así
  que puedes seguir más tarde.
- Los colores, las vidas, las celebraciones y más están en **Sudoku → Ajustes** (⌘,).

### ¿Algo salió mal?

- **No aparece el botón "Abrir igualmente":** primero intenta abrir Sudoku una vez (paso 1) y luego
  vuelve a mirar en Ajustes del Sistema. El botón solo aparece después de intentar abrir la app.
- **El aviso dice que la app está dañada:** a veces pasa con apps descargadas. Abre la app
  **Terminal**, pega la línea de abajo, pulsa Intro y vuelve a abrir Sudoku:

  ```sh
  xattr -dr com.apple.quarantine /Applications/Sudoku.app
  ```

- **¿Sigues atascado o encontraste un error?** En Sudoku, elige **Ayuda → Informar de un
  problema…**, o [abre un issue](https://github.com/vg0904/Sudoku/issues/new) aquí en GitHub.

Si prefieres no abrir una app que no está registrada con Apple, cualquiera con Xcode puede
[compilarla desde el código fuente](#primeros-pasos).

## Funcionalidades

- **Tableros aleatorios con solución única** en tres niveles de dificultad, generados fuera del
  hilo principal para que la ventana nunca se congele.
- **Vidas** (de 1 a 5 o ilimitadas): cada error cuesta un corazón. Las respuestas correctas quedan
  fijas y solo se pueden borrar los errores, así que una tecla pulsada por accidente no cuesta nada.
- **Ayudas visuales**: resaltar la fila, la columna y el recuadro seleccionados; hacer brillar los
  números iguales; recuadros 3×3 alternados; una selección que se desliza entre celdas.
- **Progreso en el teclado numérico**: cada tecla se va llenando al colocar su número, y al
  completar los nueve celebra y se convierte en una palomita.
- **Celebraciones** al completar una fila, columna, recuadro o número, con el estilo que elijas
  (Onda, Volteo, Salto, Destello o Ninguna) y una vista previa en los Ajustes. Confeti al ganar.
- **Récords estilo arcade**: un top 10 por dificultad guardado con SwiftData. Escribes tu nombre al
  hacer récord; el último se recuerda y los anteriores están a un clic. Cada récord muestra el
  tiempo, las vidas usadas, los errores y la fecha, y puedes eliminar los que quieras (⌫ o el botón
  de la papelera).
- **Tiempos justos**: pausa con ⌘P (el tablero se oculta mientras tanto) y pausa automática al
  cambiar de app.
- **La partida se guarda**: cierra la app cuando quieras y sigue donde lo dejaste con **Continuar**
  en el menú de inicio.
- **Temas de color**: por defecto sigue el color de acento del Mac, o elige uno de ocho colores
  ajustados para leerse bien en modo claro y oscuro.
- **Accesibilidad**: VoiceOver lee el número y el estado de cada celda, y también puede decir su
  fila y columna. Todas las animaciones respetan "Reducir movimiento", además de un ajuste propio,
  "Reducir animaciones".
- **Localizado** en inglés y español, con cambio de idioma en los Ajustes sin reiniciar.
- **Nativo de Mac**: barra de herramientas con Liquid Glass, comandos de menú con atajos de
  teclado, ventana de Ajustes y una ventana aparte para los Récords.

### Atajos de teclado

| Atajo | Acción |
|---|---|
| 1–9 | Escribir un número en la celda seleccionada |
| Flechas | Mover la selección |
| ⌫ / ⌦ | Borrar un número incorrecto |
| ⌘N | Nueva partida |
| ⌘R | Borrar el tablero (pide confirmación) |
| ⌘P | Pausar / reanudar |
| ⇧⌘M | Guardar la partida y volver al menú de inicio |
| ⌘L | Abrir la ventana de Récords |
| ⌘, | Ajustes |

## Requisitos

- macOS 27 o posterior
- Xcode 27 o posterior

El proyecto no tiene dependencias externas.

## Primeros pasos

1. Clona el repositorio:

   ```sh
   git clone https://github.com/vg0904/Sudoku.git
   ```

2. Abre `Sudoku.xcodeproj` en Xcode.
3. **Configura la firma.** El proyecto viene con el equipo de desarrollo del autor. En el editor
   del proyecto, selecciona el target **Sudoku** → **Signing & Capabilities** y elige tu propio
   equipo (sirve un equipo personal gratuito). Si Xcode dice que el identificador del bundle ya está
   en uso, cámbialo por uno único, como `com.tunombre.Sudoku`.

   Por favor, no incluyas estos cambios de firma en tus pull requests.
4. Pulsa **⌘R** para compilar y ejecutar.

## Ejecutar las pruebas

La lógica está cubierta por más de 200 pruebas escritas con
[Swift Testing](https://developer.apple.com/documentation/testing).

- En Xcode: **⌘U**, o abre el navegador de pruebas (**⌘6**).
- Desde la terminal:

  ```sh
  xcodebuild test -project Sudoku.xcodeproj -scheme Sudoku -destination 'platform=macOS'
  ```

Las pruebas nunca tocan tus datos reales: los ajustes usan un `UserDefaults` aislado y los récords
una base de datos de SwiftData en memoria.

## Estructura del proyecto

```
Sudoku/
├── Model/      Lógica pura del juego: la cuadrícula, el generador, la dificultad, los récords.
├── Game/       El estado de la partida (`SudokuGame`), el reloj y los avisos de celebración.
├── Settings/   Los ajustes (guardados en UserDefaults) y la ventana de Ajustes.
├── Views/      Vistas de SwiftUI: tablero, celdas, teclado, superposiciones, confeti, récords.
└── SudokuApp.swift   Las escenas (juego, Récords, Ajustes) y los comandos de menú.
SudokuTests/    Suites de Swift Testing, un archivo por área.
```

Para ver cómo encajan las piezas, y las decisiones poco evidentes detrás de ellas, consulta
**[ARCHITECTURE.md](docs/ARCHITECTURE.md)** (en inglés).

## Sobre este proyecto

Soy estudiante, y este Sudoku es un proyecto que hago por hobby. Lo construí para aprender Swift y
los frameworks de Apple a fondo, haciendo algo que de verdad quería usar: un Sudoku limpio para mi
Mac, sin anuncios ni rastreo. Lo comparto para que otras personas puedan jugarlo, leer el código,
aprender de él y ayudar a mejorarlo.

No gano dinero con él, ni es mi intención. Por eso tampoco está notarizado: la notarización exige
pagar el Apple Developer Program (99 USD al año), algo que no tiene sentido para un proyecto
gratuito hecho para aprender. Todo el código fuente está aquí, así que siempre puedes comprobar qué
hace exactamente la app, o compilarla tú.

## Contribuir

¡Las contribuciones son bienvenidas! Lee primero **[CONTRIBUTING.md](CONTRIBUTING.md)** (en
inglés): explica las convenciones de las que depende el proyecto (aislamiento de actores,
localización, animaciones y pruebas).

Sobre el idioma: **los comentarios del código están en español**, mientras que los identificadores,
las claves de texto y la documentación están en inglés. En las contribuciones se aceptan comentarios
en cualquiera de los dos idiomas.

## Novedades

Consulta el [CHANGELOG](CHANGELOG.md) (en inglés) para ver qué cambió en cada versión.

## Licencia

Sudoku se publica bajo la [licencia MIT](LICENSE).

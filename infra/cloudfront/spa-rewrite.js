function handler(event) {
    var request = event.request;
    // Rutas sin extensión (/, /tareas, /acerca...) son rutas de Angular → index.html
    // Archivos con extensión (main.js, styles.css, favicon.ico) se sirven tal cual
    if (!request.uri.includes('.')) {
        request.uri = '/index.html';
    }
    return request;
}

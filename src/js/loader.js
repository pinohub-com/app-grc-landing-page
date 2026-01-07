// ===================================
// Sistema de Carga de Secciones
// ===================================

/**
 * Carga dinámicamente las secciones HTML desde la carpeta 'secciones'
 * Esto permite una mejor organización y mantenimiento del código
 */

const Loader = {
    /**
     * Configuración de las secciones a cargar
     * Formato: { id: 'id-del-contenedor', archivo: 'nombre-del-archivo.html' }
     */
    sections: [
        { id: 'navbar-container', file: 'navbar.html' },
        { id: 'sobre-nosotros-container', file: 'sobre-nosotros.html' },
        { id: 'servicios-container', file: 'servicios.html' },
        { id: 'consumo-container', file: 'consumo.html' },
        { id: 'credito-hipotecario-container', file: 'credito-hipotecario.html' },
        { id: 'credito-vehiculo-container', file: 'credito-vehiculo.html' },
        { id: 'credito-pensionados-container', file: 'credito-pensionados.html' },
        { id: 'seguros-container', file: 'seguros.html' },
        { id: 'alianzas-coomeva-container', file: 'alianzas-coomeva.html' },
        { id: 'footer-container', file: 'footer.html' }
    ],

    /**
     * Carga una sección individual
     * @param {string} containerId - ID del contenedor donde se insertará la sección
     * @param {string} fileName - Nombre del archivo HTML a cargar
     */
    async loadSection(containerId, fileName) {
        try {
            const container = document.getElementById(containerId);
            if (!container) {
                console.warn(`Contenedor no encontrado: ${containerId}`);
                return;
            }

            // Mostrar indicador de carga
            container.innerHTML = '<div class="loading-spinner"></div>';

            // Cargar el archivo HTML
            const response = await fetch(`secciones/${fileName}`);

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const html = await response.text();
            container.innerHTML = html;

        } catch (error) {
            console.error(`Error cargando ${fileName}:`, error);
            const container = document.getElementById(containerId);
            if (container) {
                container.innerHTML = `<div class="error-message">Error al cargar la sección</div>`;
            }
        }
    },

    /**
     * Carga todas las secciones configuradas
     */
    async loadAllSections() {

        const loadPromises = this.sections.map(section =>
            this.loadSection(section.id, section.file)
        );

        try {
            await Promise.all(loadPromises);

            // Disparar evento personalizado cuando todas las secciones estén cargadas
            document.dispatchEvent(new Event('sectionsLoaded'));
        } catch (error) {
            console.error('❌ Error cargando algunas secciones:', error);
        }
    },

    /**
     * Inicializa el loader cuando el DOM esté listo
     */
    init() {
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => {
                this.loadAllSections();
            });
        } else {
            this.loadAllSections();
        }
    }
};

// Auto-inicializar el loader
Loader.init();


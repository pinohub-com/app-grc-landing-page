// ===================================
// Esperar a que las secciones se carguen
// ===================================
document.addEventListener('sectionsLoaded', function() {
    console.log('🚀 Inicializando funcionalidad de la página...');
    initializeApp();
});

// ===================================
// Función Principal de Inicialización
// ===================================
function initializeApp() {
    initNavigation();
    initScrollEffects();
    initAnimations();
    initContactForm();
    initNewsletterForm();
    initScrollToTop();
    initActiveNavigation();
    initParallax();
    initServiceCards();
    initLanguageToggle();
    initFAQ();
    initExpandableCards();
    initVideoSlider();
    updateFooterYear();
    logWelcomeMessage();
}

// ===================================
// Navigation & Mobile Menu
// ===================================
function initNavigation() {
    const hamburger = document.getElementById('hamburger');
    const navMenu = document.getElementById('nav-menu');
    const navLinks = document.querySelectorAll('.nav-link');
    
    if (!hamburger || !navMenu) return;

    // Toggle mobile menu
    hamburger.addEventListener('click', () => {
        hamburger.classList.toggle('active');
        navMenu.classList.toggle('active');
    });

    // Close mobile menu when clicking on a link
    navLinks.forEach(link => {
        link.addEventListener('click', () => {
            hamburger.classList.remove('active');
            navMenu.classList.remove('active');
        });
    });
}

// ===================================
// Language Toggle
// ===================================
function initLanguageToggle() {
    const languageToggle = document.getElementById('language-toggle');
    if (!languageToggle) return;

    // Get current language from localStorage or default to 'es'
    let currentLang = localStorage.getItem('language') || 'es';
    
    // Update button text
    updateLanguageButton(currentLang);

    languageToggle.addEventListener('click', () => {
        // Toggle between 'es' and 'en'
        currentLang = currentLang === 'es' ? 'en' : 'es';
        localStorage.setItem('language', currentLang);
        updateLanguageButton(currentLang);
        
        // Update page language attribute
        document.documentElement.lang = currentLang;
        
        // Here you can add logic to translate the page content
        // For now, we just toggle the button text
        console.log(`Idioma cambiado a: ${currentLang}`);
    });
}

function updateLanguageButton(lang) {
    const langCode = document.querySelector('.lang-code');
    if (langCode) {
        langCode.textContent = lang.toUpperCase();
    }
}

// ===================================
// FAQ Accordion
// ===================================
function initFAQ() {
    const faqItems = document.querySelectorAll('.faq-item');
    
    faqItems.forEach(item => {
        const question = item.querySelector('.faq-question');
        if (question) {
            question.addEventListener('click', () => {
                // Close other items
                faqItems.forEach(otherItem => {
                    if (otherItem !== item) {
                        otherItem.classList.remove('active');
                    }
                });
                // Toggle current item
                item.classList.toggle('active');
            });
        }
    });
}

// ===================================
// Expandable Service Cards
// ===================================
function initExpandableCards() {
    const expandableCards = document.querySelectorAll('.service-card.expandable');
    
    expandableCards.forEach(card => {
        const expandBtn = card.querySelector('.expand-btn');
        if (expandBtn) {
            expandBtn.addEventListener('click', () => {
                card.classList.toggle('expanded');
            });
        }
    });
}

// ===================================
// Video Slider
// ===================================
function initVideoSlider() {
    const slider = document.getElementById('video-slider');
    if (!slider) return;

    const slides = slider.querySelectorAll('.video-slide');
    const dots = document.querySelectorAll('.video-dots .dot');
    const prevBtn = slider.querySelector('.slider-btn.prev');
    const nextBtn = slider.querySelector('.slider-btn.next');
    
    let currentSlide = 0;
    const totalSlides = slides.length;

    function showSlide(index) {
        // Pausar todos los videos
        slides.forEach(slide => {
            const video = slide.querySelector('video');
            if (video) {
                video.pause();
                video.currentTime = 0;
            }
        });

        // Ocultar todas las slides
        slides.forEach((slide, i) => {
            slide.classList.remove('active');
            if (i === index) {
                slide.classList.add('active');
            }
        });

        // Actualizar dots
        dots.forEach((dot, i) => {
            dot.classList.remove('active');
            if (i === index) {
                dot.classList.add('active');
            }
        });

        currentSlide = index;
    }

    function nextSlide() {
        const next = (currentSlide + 1) % totalSlides;
        showSlide(next);
    }

    function prevSlide() {
        const prev = (currentSlide - 1 + totalSlides) % totalSlides;
        showSlide(prev);
    }

    // Event listeners para botones
    if (nextBtn) {
        nextBtn.addEventListener('click', nextSlide);
    }
    if (prevBtn) {
        prevBtn.addEventListener('click', prevSlide);
    }

    // Event listeners para dots
    dots.forEach((dot, index) => {
        dot.addEventListener('click', () => {
            showSlide(index);
        });
    });

    // Auto-play opcional (comentado por defecto)
    // setInterval(nextSlide, 5000);
}

// ===================================
// Scroll Effects
// ===================================
function initScrollEffects() {
    const navbar = document.getElementById('navbar');
    
    window.addEventListener('scroll', () => {
        if (navbar && window.scrollY > 100) {
            navbar.classList.add('scrolled');
        } else if (navbar) {
            navbar.classList.remove('scrolled');
        }
    });

    // Smooth Scrolling for Anchor Links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                const offset = 80;
                const targetPosition = target.offsetTop - offset;
                window.scrollTo({
                    top: targetPosition,
                    behavior: 'smooth'
                });
            }
        });
    });

    // Scroll Indicator Click
    const scrollIndicator = document.querySelector('.scroll-indicator');
    if (scrollIndicator) {
        scrollIndicator.addEventListener('click', () => {
            const servicesSection = document.getElementById('servicios');
            if (servicesSection) {
                servicesSection.scrollIntoView({ behavior: 'smooth' });
            }
        });
    }
}

// ===================================
// Animations (Counter & Fade-in)
// ===================================
function initAnimations() {
    // Counter Animation
    const observerOptions = {
        threshold: 0.5,
        rootMargin: '0px'
    };

    const animateCounter = (element) => {
        const target = parseInt(element.getAttribute('data-target'));
        const duration = 2000;
        const increment = target / (duration / 16);
        let current = 0;

        const updateCounter = () => {
            current += increment;
            if (current < target) {
                element.textContent = Math.floor(current);
                requestAnimationFrame(updateCounter);
            } else {
                element.textContent = target;
            }
        };

        updateCounter();
    };

    const statsObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const counters = entry.target.querySelectorAll('.stat-number');
                counters.forEach(counter => {
                    if (counter.textContent === '0') {
                        animateCounter(counter);
                    }
                });
                statsObserver.unobserve(entry.target);
            }
        });
    }, observerOptions);

    const statsSection = document.querySelector('.stats');
    if (statsSection) {
        statsObserver.observe(statsSection);
    }

    // Fade-in Animation
    const fadeInObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, {
        threshold: 0.1,
        rootMargin: '0px'
    });

    const cards = document.querySelectorAll('.service-card, .project-card, .tech-category');
    cards.forEach(card => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(30px)';
        card.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        fadeInObserver.observe(card);
    });
}

// ===================================
// EmailJS Configuration
// ===================================
// IMPORTANTE: Reemplaza estos valores con los tuyos de EmailJS
const EMAILJS_CONFIG = {
    serviceID: 'TU_SERVICE_ID',      // Reemplazar con tu Service ID
    templateID: 'TU_TEMPLATE_ID',    // Reemplazar con tu Template ID
    publicKey: 'TU_PUBLIC_KEY'       // Reemplazar con tu Public Key
};

// Inicializar EmailJS
(function() {
    emailjs.init(EMAILJS_CONFIG.publicKey);
})();

// ===================================
// Contact Form Handling with EmailJS
// ===================================
function initContactForm() {
    const contactForm = document.getElementById('contactForm');

    if (!contactForm) return;
    contactForm.addEventListener('submit', (e) => {
        e.preventDefault();

        const name = document.getElementById('name').value;
        const email = document.getElementById('email').value;
        const subject = document.getElementById('subject').value;
        const message = document.getElementById('message').value;

        // Basic validation
        if (!name || !email || !subject || !message) {
            showNotification('Por favor, completa todos los campos', 'error');
            return;
        }

        if (!validateEmail(email)) {
            showNotification('Por favor, ingresa un email válido', 'error');
            return;
        }

        // Mostrar indicador de carga
        const submitBtn = contactForm.querySelector('button[type="submit"]');
        const originalText = submitBtn.innerHTML;
        submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Enviando...';
        submitBtn.disabled = true;

        // Preparar parámetros para EmailJS
        const templateParams = {
            from_name: name,
            from_email: email,
            subject: subject,
            message: message,
            to_email: 'cefernal.dev@gmail.com'
        };

        // Enviar email usando EmailJS
        emailjs.send(EMAILJS_CONFIG.serviceID, EMAILJS_CONFIG.templateID, templateParams)
            .then(function(response) {
                console.log('Email enviado exitosamente!', response.status, response.text);
                showNotification('¡Mensaje enviado con éxito! Te contactaremos pronto.', 'success');
                contactForm.reset();
                
                // Restaurar botón
                submitBtn.innerHTML = originalText;
                submitBtn.disabled = false;
            }, function(error) {
                console.error('Error al enviar email:', error);
                showNotification('Error al enviar el mensaje. Por favor, intenta de nuevo.', 'error');
                
                // Restaurar botón
                submitBtn.innerHTML = originalText;
                submitBtn.disabled = false;
            });
    });
}

// Email validation
function validateEmail(email) {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
}

// Notification system
function showNotification(message, type) {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.textContent = message;
    
    notification.style.cssText = `
        position: fixed;
        top: 100px;
        right: 20px;
        padding: 1rem 2rem;
        background-color: ${type === 'success' ? '#7ba05b' : '#d9534f'};
        color: white;
        border-radius: 12px;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
        z-index: 10000;
        animation: slideIn 0.3s ease;
        font-weight: 500;
    `;

    document.body.appendChild(notification);

    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => {
            notification.remove();
        }, 300);
    }, 3000);
}

// Add notification animations
const style = document.createElement('style');
style.textContent = `
    @keyframes slideIn {
        from {
            transform: translateX(400px);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
    @keyframes slideOut {
        from {
            transform: translateX(0);
            opacity: 1;
        }
        to {
            transform: translateX(400px);
            opacity: 0;
        }
    }
`;
document.head.appendChild(style);

// ===================================
// Newsletter Form
// ===================================
function initNewsletterForm() {
    const newsletterForm = document.querySelector('.newsletter-form');

    if (!newsletterForm) return;

    newsletterForm.addEventListener('submit', (e) => {
        e.preventDefault();
        const emailInput = newsletterForm.querySelector('input[type="email"]');
        
        if (emailInput.value && validateEmail(emailInput.value)) {
            showNotification('¡Suscripción exitosa! Gracias por unirte.', 'success');
            emailInput.value = '';
        } else {
            showNotification('Por favor, ingresa un email válido', 'error');
        }
    });
}

// ===================================
// Scroll to Top Button
// ===================================
function initScrollToTop() {
    const scrollTopBtn = document.getElementById('scrollTop');

    if (!scrollTopBtn) return;

    window.addEventListener('scroll', () => {
        if (window.scrollY > 500) {
            scrollTopBtn.classList.add('active');
        } else {
            scrollTopBtn.classList.remove('active');
        }
    });

    scrollTopBtn.addEventListener('click', () => {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    });
}

// ===================================
// Active Navigation Link on Scroll
// ===================================
function initActiveNavigation() {
    const navLinks = document.querySelectorAll('.nav-link');
    
    window.addEventListener('scroll', () => {
        let current = '';
        const sections = document.querySelectorAll('section');
        
        sections.forEach(section => {
            const sectionTop = section.offsetTop;
            const sectionHeight = section.clientHeight;
            if (scrollY >= (sectionTop - 200)) {
                current = section.getAttribute('id');
            }
        });

        navLinks.forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('href') === `#${current}`) {
                link.classList.add('active');
            }
        });
    });
}

// ===================================
// Parallax Effect on Hero Section
// ===================================
function initParallax() {
    window.addEventListener('scroll', () => {
        const scrolled = window.scrollY;
        const hero = document.querySelector('.hero-content');
        if (hero) {
            hero.style.transform = `translateY(${scrolled * 0.3}px)`;
        }
    });
}

// ===================================
// Lazy Loading for Images (if you add images later)
// ===================================
if ('IntersectionObserver' in window) {
    const imageObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                img.src = img.dataset.src;
                img.classList.add('loaded');
                imageObserver.unobserve(img);
            }
        });
    });

    const lazyImages = document.querySelectorAll('img[data-src]');
    lazyImages.forEach(img => imageObserver.observe(img));
}

// ===================================
// Enhanced Hover Effects for Service Cards
// ===================================
function initServiceCards() {
    const serviceCards = document.querySelectorAll('.service-card');

    serviceCards.forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.backgroundColor = '#ffffff';
        });
        
        card.addEventListener('mouseleave', function() {
            this.style.backgroundColor = '#e8e4d0';
        });
    });
}

// ===================================
// Dynamic Year in Footer
// ===================================
function updateFooterYear() {
    const footerYear = document.querySelector('.footer-bottom p');
    if (footerYear) {
        const currentYear = new Date().getFullYear();
        footerYear.textContent = `© ${currentYear} PinoHub. Todos los derechos reservados.`;
    }
}

// ===================================
// Console Message
// ===================================
function logWelcomeMessage() {
    console.log('%c🧠 PinoHub - Desarrollo de Software con IA', 'color: #9db56c; font-size: 20px; font-weight: bold;');
    console.log('%c¿Interesado en trabajar con nosotros? Contáctanos!', 'color: #4a5a3f; font-size: 14px;');
}

// ===================================
// Performance Optimization: Debounce Function
// ===================================
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Apply debounce to scroll event
const debouncedScroll = debounce(() => {
    // Scroll-related operations
}, 10);

window.addEventListener('scroll', debouncedScroll);


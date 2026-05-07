// PDF.js Configuration
pdfjsLib.GlobalWorkerOptions.workerSrc = 'js/pdf.worker.min.js';

let pdfDoc = null,
    pageNum = 1,
    pageIsRendering = false,
    pageNumIsPending = null,
    scale = 1.5,
    canvas = document.querySelector('#pdf-render'),
    ctx = canvas.getContext('2d');

// Render the page
const renderPage = num => {
    pageIsRendering = true;

    // Get page
    pdfDoc.getPage(num).then(page => {
        const viewport = page.getViewport({ scale });
        canvas.height = viewport.height;
        canvas.width = viewport.width;

        const renderCtx = {
            canvasContext: ctx,
            viewport
        };

        page.render(renderCtx).promise.then(() => {
            pageIsRendering = false;

            if (pageNumIsPending !== null) {
                renderPage(pageNumIsPending);
                pageNumIsPending = null;
            }
        });

        // Output current page
        document.querySelector('#page-info').textContent = `Page ${num} of ${pdfDoc.numPages}`;
    });
};

// Check for pages rendering
const queueRenderPage = num => {
    if (pageIsRendering) {
        pageNumIsPending = num;
    } else {
        renderPage(num);
    }
};

// Open Protocol
window.openProtocol = (url, title) => {
    document.getElementById('viewer-title').textContent = title;
    document.getElementById('viewer-container').style.display = 'flex';
    document.getElementById('menu-fab').style.display = 'flex';
    
    // Load Document
    pdfjsLib.getDocument(url).promise.then(pdfDoc_ => {
        pdfDoc = pdfDoc_;
        pageNum = 1;
        renderPage(pageNum);
        
        // Load TOC
        loadOutline();
    }).catch(err => {
        console.error('Error loading PDF:', err);
        alert('Could not load PDF. If you are offline, ensure the file was cached previously.');
    });
};

// Close Viewer
window.closeViewer = () => {
    document.getElementById('viewer-container').style.display = 'none';
    document.getElementById('menu-fab').style.display = 'none';
    document.getElementById('nav-overlay').style.display = 'none';
};

// Load Outline (TOC)
const loadOutline = () => {
    const tocList = document.getElementById('toc-list');
    tocList.innerHTML = '<div class="nav-item">Extracting Table of Contents...</div>';
    
    pdfDoc.getOutline().then(outline => {
        if (!outline || outline.length === 0) {
            tocList.innerHTML = '<div class="nav-item">No internal TOC found. Use scroll.</div>';
            return;
        }

        tocList.innerHTML = '';
        outline.forEach(item => {
            const div = document.createElement('div');
            div.className = 'nav-item';
            div.textContent = item.title;
            div.onclick = () => {
                // Handle jumping to destination
                navigateToDestination(item.dest);
                toggleNavOverlay();
            };
            tocList.appendChild(div);
        });
    });
};

// Navigate to Destination (for TOC items)
const navigateToDestination = (dest) => {
    if (typeof dest === 'string') {
        pdfDoc.getDestination(dest).then(explicitDest => {
            navigateToExplicitDest(explicitDest);
        });
    } else {
        navigateToExplicitDest(dest);
    }
};

const navigateToExplicitDest = (explicitDest) => {
    pdfDoc.getPageIndex(explicitDest[0]).then(index => {
        pageNum = index + 1;
        queueRenderPage(pageNum);
    });
};

// Toggle Nav Overlay
window.toggleNavOverlay = () => {
    const overlay = document.getElementById('nav-overlay');
    overlay.style.display = overlay.style.display === 'block' ? 'none' : 'block';
};

// Handle Pinch to Zoom (Simple implementation for mobile)
let initialDistance = null;
canvas.addEventListener('touchstart', e => {
    if (e.touches.length === 2) {
        initialDistance = Math.hypot(
            e.touches[0].pageX - e.touches[1].pageX,
            e.touches[0].pageY - e.touches[1].pageY
        );
    }
}, { passive: true });

canvas.addEventListener('touchmove', e => {
    if (e.touches.length === 2 && initialDistance !== null) {
        const currentDistance = Math.hypot(
            e.touches[0].pageX - e.touches[1].pageX,
            e.touches[0].pageY - e.touches[1].pageY
        );
        
        if (Math.abs(currentDistance - initialDistance) > 10) {
            if (currentDistance > initialDistance) {
                scale = Math.min(scale + 0.05, 3.0);
            } else {
                scale = Math.max(scale - 0.05, 0.8);
            }
            queueRenderPage(pageNum);
            initialDistance = currentDistance;
        }
    }
}, { passive: true });

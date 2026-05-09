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
// Render the page
const renderPage = num => {
    pageIsRendering = true;

    // Get page
    pdfDoc.getPage(num).then(page => {
        const container = document.getElementById('pdf-canvas-container');
        const containerWidth = container.clientWidth - 20; // Slight padding
        
        // Calculate initial scale to fit width
        const unscaledViewport = page.getViewport({ scale: 1 });
        const fitScale = containerWidth / unscaledViewport.width;
        
        // Use fitScale as baseline, but allow user zoom to go higher
        const finalScale = Math.max(fitScale, scale - 0.5); 

        const viewport = page.getViewport({ scale: finalScale });
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
        document.querySelector('#page-info').textContent = `Pg ${num}`;
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
    tocList.innerHTML = '<div class="nav-item">Loading Table of Contents...</div>';
    
    const title = document.getElementById('viewer-title').textContent;
    
    pdfDoc.getOutline().then(outline => {
        tocList.innerHTML = '';
        
        // --- MANUAL FALLBACKS ---
        let manualTOC = [];

        if (title.includes('Adult Protocols')) {
            const rawAdultTOC = [
                ["Advanced Procedures","Emergency - Surgical Cricothyrotomy",5],
                ["Advanced Procedures","RSI",8],
                ["Advanced Procedures","Post - Intubation Management",10],
                ["Advanced Procedures","Push-Dose Pressor",11],
                ["Advanced Procedures","Orogastric Tube Insertion",13],
                ["Advanced Procedures","Pain Management / Analgesic",15],
                ["Advanced Procedures","Intraosseous (IO) Infusion",17],
                ["Advanced Procedures","Transport Ventilator",19],
                ["Advanced Procedures","BiPAP Protocol",20],
                ["Advanced Procedures","Chest Finger Thoracostomy",23],
                ["Advanced Procedures","Lateral Patellar Reduction",24],
                ["Advanced Cardiac Life Support","Adult Cardiac Guidelines",26],
                ["Advanced Cardiac Life Support","12-Lead ECG",28],
                ["Advanced Cardiac Life Support","Chest Pain -- General",31],
                ["Advanced Cardiac Life Support","Chest Pain / ACS / STEMI",33],
                ["Advanced Cardiac Life Support","REF - 12-Lead MI / Placement",35],
                ["Advanced Cardiac Life Support","V-Fib / Pulseless V-Tach",36],
                ["Advanced Cardiac Life Support","AED Protocol",38],
                ["Advanced Cardiac Life Support","LUCAS 3",39],
                ["Advanced Cardiac Life Support","Asystole / PEA",41],
                ["Advanced Cardiac Life Support","Post-Resuscitation (ROSC)",43],
                ["Advanced Cardiac Life Support","V-Tach with a Pulse",45],
                ["Advanced Cardiac Life Support","PVCs",47],
                ["Advanced Cardiac Life Support","SVT/PSVT",48],
                ["Advanced Cardiac Life Support","Atrial Fibrillation / Flutter",50],
                ["Advanced Cardiac Life Support","Bradycardia / AV Blocks",52],
                ["Medical Emergencies","Abdominal Pain",54],
                ["Medical Emergencies","Nausea / Vomiting",55],
                ["Medical Emergencies","Dehydration",56],
                ["Medical Emergencies","Hypoglycemia",57],
                ["Medical Emergencies","Hyperglycemia",59],
                ["Medical Emergencies","Hypertensive Crisis",60],
                ["Medical Emergencies","Shock (Including Sepsis)",61],
                ["Medical Emergencies","Sexual Assault",62],
                ["Medical Emergencies","Sickle Cell Crisis",63],
                ["Medical Emergencies","Psychiatric / Behavioral",64],
                ["Respiratory","Respiratory Distress / Dyspnea",65],
                ["Respiratory","CPAP",67],
                ["Neurological","Altered Mental Status / Coma",68],
                ["Neurological","CVA / Stroke",69],
                ["Neurological","REF - Cincinnati Stroke Scale",70],
                ["Neurological","REF - MEND Stroke Scale",71],
                ["Neurological","REF - LAMS Stroke Scale",72],
                ["Neurological","REF - Stroke Screen for tPA",73],
                ["Neurological","tPA Transfer Protocol",74],
                ["Neurological","Seizures / Convulsions",75],
                ["Neurological","Syncope",76],
                ["Toxicological & Environmental","Anaphylaxis / Allergic Reaction",77],
                ["Toxicological & Environmental","Overdose -- General / Opiods",78],
                ["Toxicological & Environmental","Poisoning / Haz-Mat",80],
                ["Toxicological & Environmental","Alcohol Emergencies",81],
                ["Toxicological & Environmental","Snakebite / Envenomation",82],
                ["Toxicological & Environmental","Near Drowning",83],
                ["Toxicological & Environmental","Heat Related Illness",84],
                ["Toxicological & Environmental","Hypothermia",85],
                ["Toxicological & Environmental","Electrical Shock / Lightning",86],
                ["Trauma","Abdominal / Pelvic Trauma",87],
                ["Trauma","Amputations",88],
                ["Trauma","Avulsed Teeth",89],
                ["Trauma","Burns",90],
                ["Trauma","Chest Trauma / Tension Pneumo",91],
                ["Trauma","Eye Injuries",92],
                ["Trauma","Fractures / Musculoskeletal",93],
                ["Trauma","Head Injuries",94],
                ["Trauma","Permissive Hypotension",95],
                ["Trauma","REF - Field Trauma Triage",97],
                ["Trauma","Soft Tissue / Crush Injuries",98],
                ["Trauma","Spinal Immobilization",99],
                ["Trauma","Spinal Injury / Neurogenic Shock",100],
                ["Trauma","Traumatic Cardiac Arrest",101],
                ["Trauma","Tourniquet Usage",102],
                ["Trauma","TXA Protocol",103],
                ["Trauma","START Triage",104],
                ["OB/GYN Obstetrical Emergencies","OB Complaints (Non-Delivery)",105],
                ["OB/GYN Obstetrical Emergencies","Active Delivery",107],
                ["OB/GYN Obstetrical Emergencies","Abnormal Delivery",109],
                ["OB/GYN Obstetrical Emergencies","REF - APGAR Scoring",112],
                ["OB/GYN Obstetrical Emergencies","Neonatal Resuscitation",113],
                ["OB/GYN Obstetrical Emergencies","Pre-Eclampsia / Eclampsia",114],
                ["OB/GYN Obstetrical Emergencies","Maternal Resuscitation",115],
                ["Miscellaneous","Determination of Death",116],
                ["Miscellaneous","iGel Supraglottic Airway",117],
                ["Miscellaneous","Blood Product Administration",119],
                ["Miscellaneous","PICC / Midline Access",120],
                ["Miscellaneous","Capnography Guide",121],
                ["Miscellaneous","Special Event Protocol",122],
                ["Miscellaneous","Approved Abbreviations",123],
                ["References","Citations and References",130]
            ];

            let lastCategory = "";
            rawAdultTOC.forEach(item => {
                if (item[0] !== lastCategory) {
                    const header = document.createElement('div');
                    header.style.padding = '12px 8px 4px 8px';
                    header.style.fontSize = '0.75rem';
                    header.style.fontWeight = 'bold';
                    header.style.color = 'var(--text-dim)';
                    header.style.textTransform = 'uppercase';
                    header.style.borderBottom = '1px solid rgba(255,255,255,0.1)';
                    header.textContent = item[0];
                    tocList.appendChild(header);
                    lastCategory = item[0];
                }
                const div = document.createElement('div');
                div.className = 'nav-item';
                div.innerHTML = `<span style="color:var(--accent-color); font-weight:bold; margin-right:8px;">•</span> ${item[1]}`;
                div.onclick = () => {
                    pageNum = item[2];
                    queueRenderPage(pageNum);
                    toggleNavOverlay();
                };
                tocList.appendChild(div);
            });
            return;
        } else if (title.includes('Pediatric')) {
            manualTOC = [
                { title: 'Index / TOC', page: 1 },
                { title: 'RSI / Intubation', page: 6 },
                { title: 'Pain Management', page: 11 },
                { title: 'Hypotension', page: 46 },
                { title: 'HazMat', page: 47 },
                { title: 'Seizures', page: 48 },
                { title: 'Spinal', page: 51 }
            ];
        } else if (title.includes('Formulary')) {
            manualTOC = [
                { title: 'Adenosine', page: 3 },
                { title: 'Albuterol', page: 4 },
                { title: 'Amiodarone', page: 5 },
                { title: 'Aspirin', page: 7 },
                { title: 'Epinephrine', page: 13 },
                { title: 'Fentanyl', page: 18 },
                { title: 'Ketamine', page: 20 },
                { title: 'Narcan', page: 30 },
                { title: 'Nitroglycerin', page: 31 },
                { title: 'Versed', page: 40 },
                { title: 'Zofran', page: 42 }
            ];
        } else if (title.includes('Clinical Ops')) {
            manualTOC = [
                { title: 'Lights / Sirens', page: 5 },
                { title: 'Refusal (AMA)', page: 16 },
                { title: 'DOA', page: 19 },
                { title: 'Air Medical', page: 25 },
                { title: 'Transport / Dest', page: 27 },
                { title: 'Diversion', page: 30 }
            ];
        }

        // If manual items exist, show them first
        if (manualTOC.length > 0) {
            manualTOC.forEach(item => {
                const div = document.createElement('div');
                div.className = 'nav-item';
                div.innerHTML = `<span style="color:var(--accent-color); font-weight:bold; margin-right:8px;">•</span> ${item.title}`;
                div.onclick = () => {
                    pageNum = item.page;
                    queueRenderPage(pageNum);
                    toggleNavOverlay();
                };
                tocList.appendChild(div);
            });
            
            // Add a divider if there are also internal outline items
            if (outline && outline.length > 0) {
                const hr = document.createElement('hr');
                hr.style.border = '0; border-top: 1px solid rgba(255,255,255,0.1); margin: 10px 0;';
                tocList.appendChild(hr);
            }
        }

        if (!outline || outline.length === 0) {
            if (manualTOC.length === 0) {
                tocList.innerHTML = '<div class="nav-item">No TOC items found.</div>';
            }
            return;
        }

        outline.forEach(item => {
            const div = document.createElement('div');
            div.className = 'nav-item';
            div.textContent = item.title;
            div.onclick = () => {
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

// Handle Pinch to Zoom and Swiping
let initialDistance = null;
let touchStartX = 0;
let touchStartY = 0;
const viewerContainer = document.getElementById('pdf-canvas-container');

viewerContainer.addEventListener('touchstart', e => {
    if (e.touches.length === 2) {
        initialDistance = Math.hypot(
            e.touches[0].pageX - e.touches[1].pageX,
            e.touches[0].pageY - e.touches[1].pageY
        );
    } else if (e.touches.length === 1) {
        touchStartX = e.touches[0].pageX;
        touchStartY = e.touches[0].pageY;
        initialDistance = null; // Reset pinch
    }
}, { passive: true });

viewerContainer.addEventListener('touchend', e => {
    if (e.changedTouches.length === 1 && initialDistance === null) {
        const touchEndX = e.changedTouches[0].pageX;
        const touchEndY = e.changedTouches[0].pageY;
        const deltaX = touchEndX - touchStartX;
        const deltaY = touchEndY - touchStartY;

        // More sensitive threshold: 50px
        if (Math.abs(deltaX) > 50 && Math.abs(deltaX) > Math.abs(deltaY) * 2) {
            if (deltaX > 0) {
                window.onPrevPage();
            } else {
                window.onNextPage();
            }
        }
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
                scale = Math.min(scale + 0.1, 4.0);
            } else {
                scale = Math.max(scale - 0.1, 0.5);
            }
            queueRenderPage(pageNum);
            initialDistance = currentDistance;
        }
    }
}, { passive: true });

// Open Protocol and Jump to Page
window.openToPage = (url, title, page) => {
    document.getElementById('viewer-title').textContent = title;
    document.getElementById('viewer-container').style.display = 'flex';
    document.getElementById('menu-fab').style.display = 'flex';
    
    // Load Document
    pdfjsLib.getDocument(url).promise.then(pdfDoc_ => {
        pdfDoc = pdfDoc_;
        pageNum = page; // Set starting page
        renderPage(pageNum);
        
        // Load TOC
        loadOutline();
    }).catch(err => {
        console.error('Error loading PDF:', err);
        alert('Could not load PDF.');
    });
};

// Next/Prev Buttons
window.onPrevPage = () => {
    if (pageNum <= 1) return;
    pageNum--;
    queueRenderPage(pageNum);
};

window.onNextPage = () => {
    if (pageNum >= pdfDoc.numPages) return;
    pageNum++;
    queueRenderPage(pageNum);
};

// Search Logic
window.executeSearch = async () => {
    const term = document.getElementById('pdf-search').value.toLowerCase();
    if (!term) return;

    const info = document.getElementById('page-info');
    const originalText = info.textContent;
    info.textContent = '...';

    // Start search from current page + 1, loop around
    for (let i = 1; i <= pdfDoc.numPages; i++) {
        const checkPage = ((pageNum + i - 1) % pdfDoc.numPages) + 1;
        const page = await pdfDoc.getPage(checkPage);
        const textContent = await page.getTextContent();
        const text = textContent.items.map(item => item.str).join(' ').toLowerCase();

        if (text.includes(term)) {
            pageNum = checkPage;
            queueRenderPage(pageNum);
            return;
        }
    }
    
    info.textContent = 'None';
    setTimeout(() => { info.textContent = `Pg ${pageNum}`; }, 1500);
};

// Force App Update (Clear Cache)
window.forceAppUpdate = () => {
    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.getRegistrations().then(registrations => {
            for (let registration of registrations) {
                registration.unregister();
            }
            caches.keys().then(names => {
                for (let name of names) caches.delete(name);
            });
            alert('Cache cleared. Reloading...');
            window.location.reload(true);
        });
    } else {
        window.location.reload(true);
    }
};

window.handleSearch = (event) => {
    if (event.key === 'Enter') executeSearch();
};

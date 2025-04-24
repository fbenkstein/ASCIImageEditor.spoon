// Editor state management
class EditorState {
    constructor(lines, cursorPosition) {
        this.lines = lines;
        this.cursorPosition = cursorPosition;
    }
    
    static fromTextarea(textarea) {
        const text = textarea.value;
        const textCursorPosition = textarea.selectionStart;
        const lines = [];
        let cursorPosition = null;
        let lineStart = 0;
        
        while (lineStart < text.length) {
            let lineEnd = text.indexOf("\n", lineStart);
            if (lineEnd === -1) {
                lineEnd = text.length;
            }
            
            const line = text.slice(lineStart, lineEnd).trim();
            
            if (line.length > 0 || lineEnd < text.length) {
                lines.push(line);
            }
            
            if (cursorPosition === null && textCursorPosition <= lineEnd) {
                cursorPosition = {
                    row: lines.length - 1,
                    column: textCursorPosition - lineStart,
                }
            }
            
            lineStart = lineEnd + 1;
        }
        
        if (cursorPosition === null) {
            cursorPosition = {
                row: lines.length - 1,
                column: lines[lines.length - 1]?.length || 0,
            }
        }
        
        // Pad lines to the same length
        const maxLength = Math.max(...lines.map(line => line.length));
        const paddedLines = lines.map(line => {
            while (line.length < maxLength) {
                line += '.';
            }
            return line;
        });
        
        return new EditorState(paddedLines, cursorPosition);
    }
    
    getText() {
        return this.lines.join('\n');
    }
    
    addFrame() {
        this.addColumn(0);
        this.addColumn(this.lines[0]?.length || 0);
        this.addRow(0);
        this.addRow(this.lines.length);
    }
    
    removeFrame() {
        if (this.lines.length <= 2 || this.lines[0]?.length <= 2) return;
        this.removeColumn(this.lines[0].length - 1);
        this.removeColumn(0);
        this.removeRow(this.lines.length - 1);
        this.removeRow(0);
    }
    
    addColumn(columnIndex) {
        this.lines = this.lines.map(line => {
            while (line.length < columnIndex) {
                line += '.';
            }
            return line.slice(0, columnIndex) + '.' + line.slice(columnIndex);
        });
        
        if (this.cursorPosition.column >= columnIndex) {
            this.cursorPosition.column += 1;
        }
    }
    
    removeColumn(columnIndex) {
        if (columnIndex < 0 || columnIndex >= (this.lines[0]?.length || 0)) return;
        
        this.lines = this.lines.map(line => {
            if (line.length > columnIndex) {
                return line.slice(0, columnIndex) + line.slice(columnIndex + 1);
            }
            return line;
        });
        
        if (this.cursorPosition.column > columnIndex) {
            this.cursorPosition.column -= 1;
        }
    }
    
    addRow(rowIndex) {
        const newLine = '.'.repeat(this.lines[0]?.length || 0);
        this.lines.splice(rowIndex, 0, newLine);
        
        if (this.cursorPosition.row >= rowIndex) {
            this.cursorPosition.row += 1;
        }
    }
    
    removeRow(rowIndex) {
        if (rowIndex < 0 || rowIndex >= this.lines.length || this.lines.length <= 1) return;
        
        this.lines.splice(rowIndex, 1);
        
        if (this.cursorPosition.row > rowIndex) {
            this.cursorPosition.row -= 1;
        } else if (this.cursorPosition.row === rowIndex) {
            this.cursorPosition.row = Math.max(0, rowIndex - 1);
            this.cursorPosition.column = Math.min(this.cursorPosition.column, this.lines[this.cursorPosition.row]?.length || 0);
        }
    }
    
    updateElement(textarea) {
        textarea.focus();
        textarea.setSelectionRange(0, textarea.value.length);
        document.execCommand('insertText', false, this.getText());
        
        let cursorPos = 0;
        for (let i = 0; i < this.cursorPosition.row; i++) {
            cursorPos += this.lines[i].length + 1;
        }
        cursorPos += this.cursorPosition.column;
        
        textarea.setSelectionRange(cursorPos, cursorPos);
    }
}

// Editor operations
function insertColumn() {
    const textarea = document.getElementById('ascii-editor');
    const state = EditorState.fromTextarea(textarea);
    state.addColumn(state.cursorPosition.column);
    state.updateElement(textarea);
    asciiUpdated();
}

function deleteColumn() {
    const textarea = document.getElementById('ascii-editor');
    const state = EditorState.fromTextarea(textarea);
    const column = state.cursorPosition.column;
    state.removeColumn(column > 0 ? column - 1 : 0);
    state.updateElement(textarea);
    asciiUpdated();
}

function insertRow() {
    const textarea = document.getElementById('ascii-editor');
    const state = EditorState.fromTextarea(textarea);
    state.addRow(state.cursorPosition.row + 1);
    state.updateElement(textarea);
    asciiUpdated();
}

function deleteRow() {
    const textarea = document.getElementById('ascii-editor');
    const state = EditorState.fromTextarea(textarea);
    const row = state.cursorPosition.row;
    state.removeRow(row > 0 ? row - 1 : 0);
    state.updateElement(textarea);
    asciiUpdated();
}

function addFrame() {
    const textarea = document.getElementById('ascii-editor');
    const state = EditorState.fromTextarea(textarea);
    state.addFrame();
    state.updateElement(textarea);
    asciiUpdated();
}

function deleteFrame() {
    const textarea = document.getElementById('ascii-editor');
    const state = EditorState.fromTextarea(textarea);
    state.removeFrame();
    state.updateElement(textarea);
    asciiUpdated();
}

// Ascii and context updates
function asciiUpdated() {
    const textarea = document.getElementById('ascii-editor');
    const state = EditorState.fromTextarea(textarea);
    const content = state.getText();
    localStorage.setItem('asciimage_text', content);
    renderImages();
}

function contextUpdated() {
    const textarea = document.getElementById('context-editor');
    localStorage.setItem('asciimage_context', textarea.value);
    renderImages();
}

// Image rendering
function renderImages() {
    const content = localStorage.getItem('asciimage_text') || '';
    const context = localStorage.getItem('asciimage_context') || '';
    const menubarButton = document.getElementById('menubar-button');
    const enableMenubarIcon = menubarButton.classList.contains('active');
    
    window.webkit.messageHandlers.asciimage.postMessage({
        type: 'renderImages',
        content: content,
        context: context,
        enableMenubarIcon: enableMenubarIcon,
        callback: "renderImagesCallback",
    });
}

function renderImagesCallback(result) {
    const previewContainer = document.getElementById('preview-container');
    previewContainer.innerHTML = '';
    
    if (result.error) {
        const errorDiv = document.createElement('div');
        errorDiv.className = 'error-message';
        errorDiv.textContent = result.error;
        previewContainer.appendChild(errorDiv);
        return;
    }
    
    if (!result.images || result.images.length === 0) {
        return;
    }
    
    result.images.sort((a, b) => (a.size.w * a.size.h) - (b.size.w * b.size.h));
    
    const imagesContainer = document.createElement('div');
    imagesContainer.className = 'images-container';
    
    for (const image of result.images) {
        const imgContainer = document.createElement('div');
        imgContainer.className = 'image-container';
        
        const img = document.createElement('img');
        img.src = image.path;
        img.alt = `ASCIImage Preview (${image.size.w}x${image.size.h})`;
        
        imgContainer.appendChild(img);
        
        const sizeLabel = document.createElement('div');
        sizeLabel.className = 'image-size-label';
        sizeLabel.textContent = `${image.size.w}x${image.size.h}`;
        
        imgContainer.appendChild(sizeLabel);
        imagesContainer.appendChild(imgContainer);
    }
    
    previewContainer.appendChild(imagesContainer);
}

function toggleMenubarIcon() {
    const button = document.getElementById('menubar-button');
    button.classList.toggle('active');
    button.title = button.classList.contains('active') ? 'Remove from Menubar' : 'Add to Menubar';
    renderImages();
}

// Utility functions
function adjustTextareaHeight(textarea) {
    textarea.style.height = 'auto';
    textarea.style.height = textarea.scrollHeight + 'px';
}

function showNotification() {
    const content = document.getElementById('ascii-editor').value;
    const context = document.getElementById('context-editor').value;
    
    window.webkit.messageHandlers.asciimage.postMessage({
        type: 'showNotification',
        content: content,
        context: context
    });
}

// Initialization
document.addEventListener('DOMContentLoaded', function() {
    const asciiEditor = document.getElementById('ascii-editor');
    const contextEditor = document.getElementById('context-editor');
    let asciiTimeout = null;
    let contextTimeout = null;

    asciiEditor.addEventListener('input', function() {
        adjustTextareaHeight(asciiEditor);
        if (asciiTimeout) clearTimeout(asciiTimeout);
        asciiTimeout = setTimeout(asciiUpdated, 500);
    });

    contextEditor.addEventListener('input', function() {
        adjustTextareaHeight(contextEditor);
        if (contextTimeout) clearTimeout(contextTimeout);
        contextTimeout = setTimeout(contextUpdated, 500);
    });

    const savedAscii = localStorage.getItem('asciimage_text');
    if (savedAscii) {
        asciiEditor.value = savedAscii;
    }

    const savedContext = localStorage.getItem('asciimage_context');
    if (savedContext) {
        contextEditor.value = savedContext;
    }

    adjustTextareaHeight(asciiEditor);
    adjustTextareaHeight(contextEditor);

    if (savedAscii || savedContext) {
        renderImages();
    }
});
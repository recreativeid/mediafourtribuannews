<script setup>
import { ref, watch, onMounted, nextTick } from 'vue'
import {
  Link2,
  Unlink,
  Bold,
  Italic,
  Underline,
  List,
  ListOrdered,
  Quote,
  AlignLeft,
  AlignCenter,
  AlignRight,
  AlignJustify,
  Minus,
  Video,
  Upload,
  Globe,
  X,
  Check,
  Eye,
  SlidersHorizontal,
} from 'lucide-vue-next'

const props = defineProps({
  modelValue: { type: String, default: '' },
  placeholder: { type: String, default: 'Tulis uraian berita di sini...' },
})

const emit = defineEmits(['update:modelValue'])

const editorRef = ref(null)
const mode = ref('visual') // 'visual' | 'code'
const rawHtml = ref('')
const showMoreTools = ref(true)

// Modal state
const mediaModalOpen = ref(false)
const mediaTab = ref('upload') // 'upload' | 'url' | 'video'

// Link Dialog State
const linkModalOpen = ref(false)
const linkUrl = ref('')
const linkOpenNewTab = ref(true)

// Media Form State
const uploadFile = ref(null)
const uploadPreview = ref('')
const uploadCaption = ref('')
const uploadAlign = ref('center')
const isCompressing = ref(false)

const urlInput = ref('')
const urlCaption = ref('')
const urlAlign = ref('center')

const videoUrl = ref('')
const videoCaption = ref('')

// Saved selection range
let savedRange = null

function saveSelection() {
  const sel = window.getSelection()
  if (sel && sel.rangeCount > 0) {
    savedRange = sel.getRangeAt(0)
  }
}

function restoreSelection() {
  if (savedRange) {
    const sel = window.getSelection()
    sel.removeAllRanges()
    sel.addRange(savedRange)
  }
}

// Sync content from prop
watch(
  () => props.modelValue,
  (val) => {
    if (mode.value === 'code') {
      rawHtml.value = val || ''
    } else if (editorRef.value && editorRef.value.innerHTML !== val) {
      editorRef.value.innerHTML = val || ''
    }
  },
  { immediate: true }
)

function onEditorInput() {
  if (!editorRef.value) return
  const html = editorRef.value.innerHTML
  rawHtml.value = html
  emit('update:modelValue', html)
}

function switchMode(newMode) {
  if (newMode === mode.value) return
  if (newMode === 'code') {
    rawHtml.value = editorRef.value ? editorRef.value.innerHTML : props.modelValue
    mode.value = 'code'
  } else {
    mode.value = 'visual'
    nextTick(() => {
      if (editorRef.value) {
        editorRef.value.innerHTML = rawHtml.value
      }
      emit('update:modelValue', rawHtml.value)
    })
  }
}

function onCodeInput(e) {
  const val = e.target.value
  rawHtml.value = val
  emit('update:modelValue', val)
}

// Formatting commands
function execCmd(command, value = null) {
  if (mode.value !== 'visual') return
  editorRef.value?.focus()
  restoreSelection()
  document.execCommand(command, false, value)
  saveSelection()
  onEditorInput()
}

function formatBlock(tag) {
  execCmd('formatBlock', tag)
}

// Open Link Modal
function openLinkModal() {
  saveSelection()
  linkUrl.value = 'https://'
  linkOpenNewTab.value = true
  linkModalOpen.value = true
}

function applyLink() {
  linkModalOpen.value = false
  if (!linkUrl.value || linkUrl.value === 'https://') return
  restoreSelection()
  const sel = window.getSelection()
  if (!sel || sel.isCollapsed) {
    const a = document.createElement('a')
    a.href = linkUrl.value
    a.textContent = linkUrl.value
    if (linkOpenNewTab.value) {
      a.target = '_blank'
      a.rel = 'noopener noreferrer'
    }
    insertNodeAtCursor(a)
  } else {
    execCmd('createLink', linkUrl.value)
    if (linkOpenNewTab.value && editorRef.value) {
      const anchors = editorRef.value.querySelectorAll('a')
      anchors.forEach((a) => {
        if (a.href === linkUrl.value) {
          a.target = '_blank'
          a.rel = 'noopener noreferrer'
        }
      })
      onEditorInput()
    }
  }
}

function removeLink() {
  execCmd('unlink')
}

// Insert HTML at cursor
function insertHtmlAtCursor(html) {
  editorRef.value?.focus()
  restoreSelection()
  const sel = window.getSelection()
  if (sel && sel.rangeCount > 0) {
    const range = sel.getRangeAt(0)
    range.deleteContents()
    const el = document.createElement('div')
    el.innerHTML = html
    const frag = document.createDocumentFragment()
    let node
    let lastNode
    while ((node = el.firstChild)) {
      lastNode = frag.appendChild(node)
    }
    range.insertNode(frag)
    if (lastNode) {
      range.setStartAfter(lastNode)
      range.collapse(true)
      sel.removeAllRanges()
      sel.addRange(range)
    }
  } else if (editorRef.value) {
    editorRef.value.innerHTML += html
  }
  onEditorInput()
}

function insertNodeAtCursor(node) {
  editorRef.value?.focus()
  restoreSelection()
  const sel = window.getSelection()
  if (sel && sel.rangeCount > 0) {
    const range = sel.getRangeAt(0)
    range.deleteContents()
    range.insertNode(node)
    range.setStartAfter(node)
    range.collapse(true)
    sel.removeAllRanges()
    sel.addRange(range)
  } else if (editorRef.value) {
    editorRef.value.appendChild(node)
  }
  onEditorInput()
}

function openMediaModal() {
  saveSelection()
  uploadFile.value = null
  uploadPreview.value = ''
  uploadCaption.value = ''
  urlInput.value = ''
  urlCaption.value = ''
  videoUrl.value = ''
  videoCaption.value = ''
  mediaModalOpen.value = true
}

// Client-side image compressor (converts to optimized WebP/JPEG)
async function compressImageFile(file, maxWidth = 1200, quality = 0.82) {
  return new Promise((resolve) => {
    if (file.type === 'image/svg+xml') {
      const reader = new FileReader()
      reader.onload = () => resolve(reader.result)
      reader.readAsDataURL(file)
      return
    }

    const reader = new FileReader()
    reader.onload = (e) => {
      const img = new Image()
      img.onload = () => {
        let width = img.width
        let height = img.height

        if (width > maxWidth) {
          height = Math.round((height * maxWidth) / width)
          width = maxWidth
        }

        const canvas = document.createElement('canvas')
        canvas.width = width
        canvas.height = height
        const ctx = canvas.getContext('2d')
        ctx.drawImage(img, 0, 0, width, height)

        try {
          const webpData = canvas.toDataURL('image/webp', quality)
          if (webpData.startsWith('data:image/webp')) {
            resolve(webpData)
            return
          }
        } catch (err) {}

        resolve(canvas.toDataURL('image/jpeg', quality))
      }
      img.src = e.target.result
    }
    reader.readAsDataURL(file)
  })
}

async function onFileSelected(e) {
  const f = e.target.files?.[0]
  if (!f) return
  isCompressing.value = true
  try {
    const optimizedDataUrl = await compressImageFile(f)
    uploadPreview.value = optimizedDataUrl
  } finally {
    isCompressing.value = false
  }
}

function insertUploadedImage() {
  if (!uploadPreview.value) return
  mediaModalOpen.value = false

  const captionHtml = uploadCaption.value.trim()
    ? `<figcaption style="text-align: center; font-size: 11px; color: #64748b; font-style: italic; margin-top: 6px;">${uploadCaption.value.trim()}</figcaption>`
    : ''

  const html = `<figure style="text-align: center; margin: 1.5rem 0;">
  <img src="${uploadPreview.value}" alt="${uploadCaption.value || 'Foto Berita'}" style="border-radius: 0.75rem; max-width: 100%; height: auto; display: inline-block; box-shadow: 0 1px 3px rgba(0,0,0,0.1);" />
  ${captionHtml}
</figure><p><br></p>`

  insertHtmlAtCursor(html)
}

function insertUrlImage() {
  if (!urlInput.value.trim()) return
  mediaModalOpen.value = false

  const captionHtml = urlCaption.value.trim()
    ? `<figcaption style="text-align: center; font-size: 11px; color: #64748b; font-style: italic; margin-top: 6px;">${urlCaption.value.trim()}</figcaption>`
    : ''

  const html = `<figure style="text-align: center; margin: 1.5rem 0;">
  <img src="${urlInput.value.trim()}" alt="${urlCaption.value || 'Foto Berita'}" style="border-radius: 0.75rem; max-width: 100%; height: auto; display: inline-block; box-shadow: 0 1px 3px rgba(0,0,0,0.1);" />
  ${captionHtml}
</figure><p><br></p>`

  insertHtmlAtCursor(html)
}

function insertVideo() {
  const url = videoUrl.value.trim()
  if (!url) return
  mediaModalOpen.value = false

  let youtubeId = ''
  const ytMatch = url.match(/(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))([\w-]{11})/)
  if (ytMatch) {
    youtubeId = ytMatch[1]
  }

  let embedHtml = ''
  if (youtubeId) {
    embedHtml = `<div class="video-container" style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; border-radius: 0.75rem; margin: 1.5rem 0; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);">
  <iframe src="https://www.youtube.com/embed/${youtubeId}" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; border-radius: 0.75rem;"></iframe>
</div>`
  } else {
    embedHtml = `<div style="margin: 1.5rem 0; text-align: center;">
  <a href="${url}" target="_blank" rel="noopener noreferrer" style="display: inline-flex; align-items: center; gap: 6px; padding: 10px 16px; border-radius: 12px; background: #0B2563; color: #ffffff; font-weight: bold; font-size: 12px; text-decoration: none;">
    ▶ Tonton Video Terkait
  </a>
</div>`
  }

  const captionHtml = videoCaption.value.trim()
    ? `<p style="text-align: center; font-size: 11px; color: #64748b; font-style: italic; margin-top: -6px; margin-bottom: 12px;">${videoCaption.value.trim()}</p>`
    : ''

  insertHtmlAtCursor(`${embedHtml}${captionHtml}<p><br></p>`)
}

onMounted(() => {
  if (editorRef.value) {
    editorRef.value.innerHTML = props.modelValue || ''
  }
})
</script>

<template>
  <div class="wp-editor-wrap border border-slate-300 rounded-xl bg-slate-50 overflow-hidden shadow-xs">
    <!-- TOP BAR: [Add Media] button on left + [Visual] [Code] tabs on right -->
    <div class="wp-editor-top flex items-end justify-between px-3 pt-2.5 pb-0 bg-[#f0f0f1] border-b border-slate-300">
      <!-- Add Media Button (Matches Gambar 2) -->
      <button
        type="button"
        @click="openMediaModal"
        class="inline-flex items-center gap-1.5 px-3 py-1.5 mb-1.5 rounded bg-white hover:bg-[#f6f7f7] border border-[#2271b1] text-[#2271b1] hover:text-[#135e96] text-xs font-bold shadow-2xs transition-colors"
      >
        <span class="text-sm">📷♫</span>
        <span>Add Media</span>
      </button>

      <!-- Visual vs Code Tabs (Matches Gambar 2) -->
      <div class="flex items-end space-x-1">
        <button
          type="button"
          @click="switchMode('visual')"
          class="px-3.5 py-1.5 text-xs font-semibold rounded-t border-t border-l border-r transition-colors"
          :class="mode === 'visual'
            ? 'bg-white text-slate-800 border-slate-300 -mb-px pb-2 font-bold shadow-2xs'
            : 'bg-[#dcdcde] text-slate-600 border-transparent hover:bg-[#eaeaea]'"
        >
          Visual
        </button>
        <button
          type="button"
          @click="switchMode('code')"
          class="px-3.5 py-1.5 text-xs font-semibold rounded-t border-t border-l border-r transition-colors"
          :class="mode === 'code'
            ? 'bg-white text-slate-800 border-slate-300 -mb-px pb-2 font-bold shadow-2xs'
            : 'bg-[#dcdcde] text-slate-600 border-transparent hover:bg-[#eaeaea]'"
        >
          Code
        </button>
      </div>
    </div>

    <!-- WORDPRESS CLASSIC TOOLBAR (Visual Mode) -->
    <div
      v-show="mode === 'visual'"
      class="wp-toolbar px-2 py-1.5 bg-white border-b border-slate-200 flex flex-wrap items-center gap-1 text-slate-700"
    >
      <!-- Format Paragraph / Headings Dropdown -->
      <select
        @change="(e) => formatBlock(e.target.value)"
        class="h-7 px-2 rounded border border-slate-300 bg-white text-xs font-medium focus:outline-none"
      >
        <option value="p">Paragraph</option>
        <option value="h2">Heading 2</option>
        <option value="h3">Heading 3</option>
        <option value="h4">Heading 4</option>
        <option value="blockquote">Blockquote</option>
      </select>

      <span class="w-px h-5 bg-slate-300 mx-0.5"></span>

      <!-- Bold (B) -->
      <button
        type="button"
        @click="execCmd('bold')"
        class="w-7 h-7 rounded hover:bg-slate-100 flex items-center justify-center font-bold text-sm"
        title="Bold (Ctrl+B)"
      >
        <span class="font-black">B</span>
      </button>

      <!-- Italic (I) -->
      <button
        type="button"
        @click="execCmd('italic')"
        class="w-7 h-7 rounded hover:bg-slate-100 flex items-center justify-center italic font-serif text-sm"
        title="Italic (Ctrl+I)"
      >
        <span class="italic font-bold">I</span>
      </button>

      <!-- Bullet List -->
      <button
        type="button"
        @click="execCmd('insertUnorderedList')"
        class="w-7 h-7 rounded hover:bg-slate-100 flex items-center justify-center text-xs"
        title="Bulleted List"
      >
        <List class="w-3.5 h-3.5" />
      </button>

      <!-- Numbered List -->
      <button
        type="button"
        @click="execCmd('insertOrderedList')"
        class="w-7 h-7 rounded hover:bg-slate-100 flex items-center justify-center text-xs"
        title="Numbered List"
      >
        <ListOrdered class="w-3.5 h-3.5" />
      </button>

      <!-- Blockquote (“”) -->
      <button
        type="button"
        @click="execCmd('formatBlock', 'blockquote')"
        class="w-7 h-7 rounded hover:bg-slate-100 flex items-center justify-center font-serif text-base font-bold leading-none"
        title="Blockquote"
      >
        &ldquo;&rdquo;
      </button>

      <span class="w-px h-5 bg-slate-300 mx-0.5"></span>

      <!-- Align Left -->
      <button
        type="button"
        @click="execCmd('justifyLeft')"
        class="w-7 h-7 rounded hover:bg-slate-100 flex items-center justify-center"
        title="Rata Kiri"
      >
        <AlignLeft class="w-3.5 h-3.5" />
      </button>

      <!-- Align Center -->
      <button
        type="button"
        @click="execCmd('justifyCenter')"
        class="w-7 h-7 rounded hover:bg-slate-100 flex items-center justify-center"
        title="Rata Tengah"
      >
        <AlignCenter class="w-3.5 h-3.5" />
      </button>

      <!-- Align Right -->
      <button
        type="button"
        @click="execCmd('justifyRight')"
        class="w-7 h-7 rounded hover:bg-slate-100 flex items-center justify-center"
        title="Rata Kanan"
      >
        <AlignRight class="w-3.5 h-3.5" />
      </button>

      <!-- Align Justify (Rata Kanan Kiri) -->
      <button
        type="button"
        @click="execCmd('justifyFull')"
        class="w-7 h-7 rounded hover:bg-slate-100 flex items-center justify-center"
        title="Rata Kanan Kiri (Justify)"
      >
        <AlignJustify class="w-3.5 h-3.5" />
      </button>

      <span class="w-px h-5 bg-slate-300 mx-0.5"></span>

      <!-- Insert Link (🔗) -->
      <button
        type="button"
        @click="openLinkModal"
        class="w-7 h-7 rounded hover:bg-slate-100 flex items-center justify-center text-[#2271b1]"
        title="Sisipkan / Edit Link (Backlink)"
      >
        <Link2 class="w-3.5 h-3.5" />
      </button>

      <!-- Remove Link -->
      <button
        type="button"
        @click="removeLink"
        class="w-7 h-7 rounded hover:bg-slate-100 flex items-center justify-center text-slate-400 hover:text-red-600"
        title="Hapus Link"
      >
        <Unlink class="w-3.5 h-3.5" />
      </button>

      <!-- Horizontal Line (—) -->
      <button
        type="button"
        @click="execCmd('insertHorizontalRule')"
        class="w-7 h-7 rounded hover:bg-slate-100 flex items-center justify-center font-bold"
        title="Garis Pemisah (Horizontal Rule)"
      >
        <Minus class="w-3.5 h-3.5" />
      </button>

      <!-- Toggle Kitchen Sink / More Tools -->
      <button
        type="button"
        @click="showMoreTools = !showMoreTools"
        class="w-7 h-7 rounded hover:bg-slate-100 flex items-center justify-center text-slate-500"
        title="Alat Tambahan"
      >
        <SlidersHorizontal class="w-3.5 h-3.5" />
      </button>
    </div>

    <!-- ROW 2 TOOLBAR (Optional Extra Tools) -->
    <div
      v-show="mode === 'visual' && showMoreTools"
      class="wp-toolbar-row2 px-2 py-1 bg-[#fafafa] border-b border-slate-200 flex flex-wrap items-center gap-1 text-slate-600 text-xs"
    >
      <button
        type="button"
        @click="execCmd('underline')"
        class="px-2 py-0.5 rounded hover:bg-slate-200 underline font-semibold text-xs"
        title="Underline"
      >
        <u>U</u>
      </button>
      <button
        type="button"
        @click="execCmd('strikeThrough')"
        class="px-2 py-0.5 rounded hover:bg-slate-200 line-through text-xs"
        title="Coret (Strikethrough)"
      >
        <s>abc</s>
      </button>
      <span class="w-px h-4 bg-slate-300 mx-1"></span>
      <button
        type="button"
        @click="execCmd('removeFormat')"
        class="px-2 py-0.5 rounded hover:bg-slate-200 text-xs text-slate-500"
        title="Hapus Format"
      >
        Clear Format
      </button>
      <span class="text-[11px] text-slate-400 ml-auto hidden sm:inline">
        💡 Blok teks lalu klik 🔗 untuk membuat tautan
      </span>
    </div>

    <!-- VISUAL EDITABLE AREA (What You See Is What You Get) -->
    <div
      v-show="mode === 'visual'"
      ref="editorRef"
      contenteditable="true"
      @input="onEditorInput"
      @blur="saveSelection"
      @keyup="saveSelection"
      @mouseup="saveSelection"
      class="p-4 sm:p-5 min-h-[300px] max-h-[520px] overflow-y-auto bg-white focus:outline-none article-prose text-sm sm:text-base leading-relaxed text-slate-900"
      :data-placeholder="placeholder"
    ></div>

    <!-- CODE VIEW (RAW HTML TEXTAREA) -->
    <textarea
      v-show="mode === 'code'"
      :value="rawHtml"
      @input="onCodeInput"
      rows="14"
      class="w-full p-4 font-mono text-xs text-slate-800 bg-[#f8f9fa] focus:outline-none min-h-[300px] border-none"
      placeholder="Kode HTML isi berita..."
    ></textarea>

    <!-- FOOTER STATUS BAR -->
    <div class="px-3 py-1.5 bg-[#f0f0f1] border-t border-slate-300 flex items-center justify-between text-[11px] text-slate-500">
      <span>Mode Editor: <strong>{{ mode === 'visual' ? 'Visual (Ketik Langsung Tanpa Kode)' : 'Kode HTML' }}</strong></span>
      <span>Klik <strong>[Add Media]</strong> untuk menyisipkan gambar/video di tengah tulisan</span>
    </div>

    <!-- ========================================================================= -->
    <!-- MODAL 1: ADD MEDIA (UPLOAD FOTO AUTO-COMPRESS, LINK GAMBAR, LINK VIDEO)   -->
    <!-- ========================================================================= -->
    <div v-if="mediaModalOpen" class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4">
      <div class="fixed inset-0 bg-slate-950/70 backdrop-blur-xs" @click="mediaModalOpen = false"></div>
      <div class="relative bg-white rounded-2xl w-full max-w-xl overflow-hidden shadow-2xl z-10 space-y-4">
        <!-- Header Modal -->
        <div class="px-5 py-3.5 bg-[#0B2563] text-white flex items-center justify-between">
          <h3 class="text-sm sm:text-base font-bold flex items-center gap-2">
            <span>📷♫</span>
            <span>Add Media (Sisipkan Foto / Video / Tautan)</span>
          </h3>
          <button type="button" @click="mediaModalOpen = false" class="p-1 rounded hover:bg-white/10">
            <X class="w-4 h-4" />
          </button>
        </div>

        <!-- Navigation Tabs -->
        <div class="px-5 pt-1">
          <div class="flex rounded-lg bg-slate-100 p-1 text-xs font-bold">
            <button
              type="button"
              @click="mediaTab = 'upload'"
              class="flex-1 py-1.5 rounded transition-all flex items-center justify-center gap-1.5"
              :class="mediaTab === 'upload' ? 'bg-white text-[#0B2563] shadow-xs' : 'text-slate-600 hover:text-slate-900'"
            >
              <Upload class="w-3.5 h-3.5" /> Upload Foto (Auto-Compress)
            </button>
            <button
              type="button"
              @click="mediaTab = 'url'"
              class="flex-1 py-1.5 rounded transition-all flex items-center justify-center gap-1.5"
              :class="mediaTab === 'url' ? 'bg-white text-[#0B2563] shadow-xs' : 'text-slate-600 hover:text-slate-900'"
            >
              <Globe class="w-3.5 h-3.5" /> Link Foto (Preview)
            </button>
            <button
              type="button"
              @click="mediaTab = 'video'"
              class="flex-1 py-1.5 rounded transition-all flex items-center justify-center gap-1.5"
              :class="mediaTab === 'video' ? 'bg-white text-[#0B2563] shadow-xs' : 'text-slate-600 hover:text-slate-900'"
            >
              <Video class="w-3.5 h-3.5" /> Link Video
            </button>
          </div>
        </div>

        <div class="px-5 pb-5">
          <!-- TAB 1: UPLOAD GAMBAR DENGAN AUTO KOMPRESI -->
          <div v-if="mediaTab === 'upload'" class="space-y-3">
            <div class="border-2 border-dashed border-slate-300 rounded-xl p-4 text-center hover:border-[#2271b1] transition-colors">
              <input
                type="file"
                accept="image/*"
                id="wp-rich-file"
                class="hidden"
                @change="onFileSelected"
              />
              <label for="wp-rich-file" class="cursor-pointer space-y-1 block">
                <Upload class="w-7 h-7 text-[#2271b1] mx-auto" />
                <div class="text-xs font-bold text-slate-800">
                  {{ isCompressing ? 'Mengompresi gambar...' : 'Klik untuk memilih foto dari komputer/HP' }}
                </div>
                <div class="text-[10px] text-slate-500">Otomatis dikompresi agar loading web tetap sangat cepat</div>
              </label>
            </div>

            <!-- Preview Gambar yang Dipilih -->
            <div v-if="uploadPreview" class="p-3 rounded-lg bg-slate-50 border border-slate-200 flex items-center gap-3">
              <img :src="uploadPreview" alt="Preview" class="w-20 h-16 rounded object-cover shrink-0 border" />
              <div class="flex-1 min-w-0">
                <span class="inline-flex items-center gap-1 text-[10px] font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded">
                  <Check class="w-3 h-3" /> Foto siap disisipkan ke posisi kursor
                </span>
                <p class="text-[11px] text-slate-500 mt-1 truncate">Foto akan muncul di dalam teks berita</p>
              </div>
            </div>

            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">Keterangan / Caption Foto (Opsional)</label>
              <input
                v-model="uploadCaption"
                placeholder="Contoh: Suasana saat konferensi pers berlangsung..."
                class="w-full px-3 py-2 rounded-lg bg-slate-50 border border-slate-200 text-xs"
              />
            </div>

            <div class="flex justify-end gap-2 pt-2">
              <button
                type="button"
                @click="mediaModalOpen = false"
                class="px-4 py-2 rounded-lg bg-slate-100 text-xs font-bold"
              >
                Batal
              </button>
              <button
                type="button"
                :disabled="!uploadPreview || isCompressing"
                @click="insertUploadedImage"
                class="px-5 py-2 rounded-lg bg-[#0B2563] hover:bg-[#D91E28] text-white text-xs font-bold disabled:opacity-50 transition-colors shadow-2xs"
              >
                Sisipkan ke Tulisan
              </button>
            </div>
          </div>

          <!-- TAB 2: LINK GAMBAR DENGAN LIVE PREVIEW -->
          <div v-else-if="mediaTab === 'url'" class="space-y-3">
            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">URL / Link Gambar *</label>
              <input
                v-model="urlInput"
                placeholder="https://example.com/foto.jpg"
                class="w-full px-3 py-2 rounded-lg bg-slate-50 border border-slate-200 text-xs"
              />
            </div>

            <!-- LIVE PREVIEW GAMBAR DARI LINK -->
            <div v-if="urlInput.trim()" class="p-3 rounded-lg bg-slate-50 border border-slate-200 space-y-1">
              <span class="text-[10px] font-bold text-slate-500 uppercase">Live Preview Gambar Sumber:</span>
              <div class="h-32 rounded overflow-hidden bg-slate-200/60 flex items-center justify-center">
                <img
                  :src="urlInput.trim()"
                  alt="Preview Link"
                  class="w-full h-full object-contain"
                  @error="(e) => (e.target.style.display = 'none')"
                />
              </div>
            </div>

            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">Keterangan / Caption Foto (Opsional)</label>
              <input
                v-model="urlCaption"
                placeholder="Kredit foto / sumber..."
                class="w-full px-3 py-2 rounded-lg bg-slate-50 border border-slate-200 text-xs"
              />
            </div>

            <div class="flex justify-end gap-2 pt-2">
              <button
                type="button"
                @click="mediaModalOpen = false"
                class="px-4 py-2 rounded-lg bg-slate-100 text-xs font-bold"
              >
                Batal
              </button>
              <button
                type="button"
                :disabled="!urlInput.trim()"
                @click="insertUrlImage"
                class="px-5 py-2 rounded-lg bg-[#0B2563] hover:bg-[#D91E28] text-white text-xs font-bold disabled:opacity-50 transition-colors shadow-2xs"
              >
                Sisipkan Gambar
              </button>
            </div>
          </div>

          <!-- TAB 3: LINK VIDEO (YOUTUBE EMBED) -->
          <div v-else-if="mediaTab === 'video'" class="space-y-3">
            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">URL Video YouTube atau Link Video *</label>
              <input
                v-model="videoUrl"
                placeholder="https://www.youtube.com/watch?v=... atau https://youtu.be/..."
                class="w-full px-3 py-2 rounded-lg bg-slate-50 border border-slate-200 text-xs"
              />
              <p class="text-[10px] text-slate-500 mt-1">Otomatis disisipkan menjadi pemutar video di posisi kursor tulisan.</p>
            </div>

            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">Keterangan Video (Opsional)</label>
              <input
                v-model="videoCaption"
                placeholder="Contoh: Liputan eksklusif siaran langsung..."
                class="w-full px-3 py-2 rounded-lg bg-slate-50 border border-slate-200 text-xs"
              />
            </div>

            <div class="flex justify-end gap-2 pt-2">
              <button
                type="button"
                @click="mediaModalOpen = false"
                class="px-4 py-2 rounded-lg bg-slate-100 text-xs font-bold"
              >
                Batal
              </button>
              <button
                type="button"
                :disabled="!videoUrl.trim()"
                @click="insertVideo"
                class="px-5 py-2 rounded-lg bg-[#0B2563] hover:bg-[#D91E28] text-white text-xs font-bold disabled:opacity-50 transition-colors shadow-2xs"
              >
                Sisipkan Video
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ========================================================================= -->
    <!-- MODAL 2: PASANG TAUTAN / BACKLINK (🔗)                                    -->
    <!-- ========================================================================= -->
    <div v-if="linkModalOpen" class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4">
      <div class="fixed inset-0 bg-slate-950/70 backdrop-blur-xs" @click="linkModalOpen = false"></div>
      <div class="relative bg-white rounded-2xl w-full max-w-md overflow-hidden shadow-2xl z-10 p-5 space-y-4">
        <div class="flex items-center justify-between pb-2 border-b border-slate-200">
          <h3 class="text-sm font-bold text-[#0B2563] flex items-center gap-2">
            <Link2 class="w-4 h-4 text-[#2271b1]" />
            Pasang Tautan (Backlink)
          </h3>
          <button type="button" @click="linkModalOpen = false" class="p-1 rounded hover:bg-slate-100">
            <X class="w-4 h-4" />
          </button>
        </div>

        <div class="space-y-3">
          <div>
            <label class="block text-xs font-bold text-slate-700 mb-1">URL Tujuan *</label>
            <input
              v-model="linkUrl"
              placeholder="https://example.com/artikel-terkait"
              class="w-full px-3.5 py-2 rounded-lg bg-slate-50 border border-slate-200 text-xs font-mono focus:bg-white focus:border-[#2271b1]"
            />
          </div>

          <label class="flex items-center gap-2 text-xs font-bold text-slate-700 cursor-pointer pt-1">
            <input v-model="linkOpenNewTab" type="checkbox" class="w-4 h-4 accent-[#2271b1] rounded" />
            <span>Buka tautan di tab baru (target="_blank")</span>
          </label>
        </div>

        <div class="flex justify-end gap-2 pt-2 border-t border-slate-100">
          <button
            type="button"
            @click="linkModalOpen = false"
            class="px-4 py-2 rounded-lg bg-slate-100 text-xs font-bold"
          >
            Batal
          </button>
          <button
            type="button"
            @click="applyLink"
            class="px-5 py-2 rounded-lg bg-[#2271b1] hover:bg-[#135e96] text-white text-xs font-bold transition-colors shadow-2xs"
          >
            Pasang Tautan
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* Placeholder handling for contenteditable */
[contenteditable]:empty:before {
  content: attr(data-placeholder);
  color: #94a3b8;
  pointer-events: none;
  display: block;
}
</style>

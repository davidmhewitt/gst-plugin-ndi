project('gst-plugin-ndi', 'vala', 'c')

vapi_dir = join_paths (meson.current_source_dir(), 'vapi')

add_project_arguments(['--vapidir', vapi_dir], language: 'vala')

dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gstreamer-1.0'),
    dependency('gstreamer-video-1.0'),
    dependency('ndi'),
]

sources = files(
    'src/gst-plugin-ndi.vala',
    'src/gst-ndi-sink.vala',
)

shared_library('gstndi', sources,
               dependencies: dependencies,
               install: true,
               install_dir: [true, false, false])


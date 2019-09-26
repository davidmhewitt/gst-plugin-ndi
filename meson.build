project('gst-plugin-ndi', 'vala', 'c')

vapi_dir = meson.current_source_dir() / 'vapi'
lib_dir = meson.current_source_dir() / 'libndi'

add_project_arguments(['--vapidir', vapi_dir], language: 'vala')

dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gstreamer-1.0'),
    dependency('gstreamer-video-1.0'),
    meson.get_compiler('vala').find_library('ndi', dirs: vapi_dir),
]

sources = files(
    'src/gst-plugin-ndi.vala',
    'src/gst-ndi-videosink.vala',
)

incdir = include_directories('include')

shared_library('gstndi', sources,
               dependencies: dependencies,
               include_directories: incdir,
               link_args: ['-L'+lib_dir, '-lndi'],
               install: true,
               install_dir: [true, false, false])


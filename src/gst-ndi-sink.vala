/*
* Copyright (c) 2019 David Hewitt <davidmhewitt@gmail.com>
*
* This library is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 2.1 of the License, or (at your option) any later version.
*
* This library is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* Lesser General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public
* License along with this library; if not, write to the Free Software
* Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
* USA
*/

namespace Gst.PluginNDI {
    class Sink : Gst.Element {
        private NDI.Send? sender;
        private NDI.VideoFrameV2 video_frame;
        private NDI.AudioFrameInterleaved16S audio_frame;
        private size_t video_buffer_size = 0;

        private uint audio_pads = 0;
        private uint video_pads = 0;

        private Gst.Base.CollectPads? collect = null;

        static construct {
            set_static_metadata (
                "NDI Video Sink",
                "Sink",
                "Stream video to an NDI network",
                "David Hewitt <davidmhewitt@gmail.com>"
            );

            var video_caps = new Gst.Caps.empty ();

            // Prepare a list of our supported pixel formats
            var pixel_format_list = GLib.Value (typeof (Gst.ValueList));
            Gst.ValueList.append_value (pixel_format_list, "UYVY");
            Gst.ValueList.append_value (pixel_format_list, "YV12");
            Gst.ValueList.append_value (pixel_format_list, "I420");
            Gst.ValueList.append_value (pixel_format_list, "NV12");
            Gst.ValueList.append_value (pixel_format_list, "BGRA");
            Gst.ValueList.append_value (pixel_format_list, "BGRx");
            Gst.ValueList.append_value (pixel_format_list, "RGBA");
            Gst.ValueList.append_value (pixel_format_list, "RGBx");

            // Advertise support any video dimensions and frame rate
            var video_struc = new Gst.Structure (
                "video/x-raw",
                "width", typeof (Gst.IntRange), 0, int32.MAX,
                "height", typeof (Gst.IntRange), 0, int32.MAX,
                "framerate", typeof (Gst.FractionRange), 0, 1, int32.MAX, 1
            );

            video_struc.set_value ("format", pixel_format_list);
            video_caps.append_structure ((owned)video_struc);

            var audio_caps = new Gst.Caps.empty ();

            // Prepare a list of our supported pixel formats
            var audio_format_list = GLib.Value (typeof (Gst.ValueList));
            Gst.ValueList.append_value (audio_format_list, "S16LE");

            var audio_struc = new Gst.Structure (
                "audio/x-raw",
                "rate", typeof (Gst.IntRange), 0, int32.MAX,
                "channels", typeof (Gst.IntRange), 0, int32.MAX
            );

            audio_struc.set_value ("format", audio_format_list);
            audio_caps.append_structure ((owned)audio_struc);

            var video_sink_template = new Gst.PadTemplate (
                "video_%u",
                Gst.PadDirection.SINK,
                Gst.PadPresence.REQUEST,
                video_caps
            );

            var audio_sink_template = new Gst.PadTemplate (
                "audio_%u",
                Gst.PadDirection.SINK,
                Gst.PadPresence.REQUEST,
                audio_caps
            );

            add_pad_template (video_sink_template);
            add_pad_template (audio_sink_template);
        }

        construct {
            NDI.initialize ();

            sender = NDI.Send.create ();
            video_frame = NDI.VideoFrameV2.create_default ();
            audio_frame = NDI.AudioFrameInterleaved16S.create_default ();

            collect = new Gst.Base.CollectPads ();
            collect.set_buffer_function (collect_pads);
            collect.set_event_function (handle_event);
        }

        public Gst.FlowReturn collect_pads (Gst.Base.CollectPads pads, Gst.Base.CollectData? data, owned Gst.Buffer buffer) {
            if (data.pad.template == get_pad_template ("video_%u")) {
                buffer.extract_dup (0, video_buffer_size, out video_frame.data);
                sender.send_video_v2 (video_frame);
                free (video_frame.data);
                return Gst.FlowReturn.OK;
            } else if (data.pad.template == get_pad_template ("audio_%u")) {
                var n_samples = buffer.get_size () / audio_frame.no_channels / sizeof(int16);
                audio_frame.no_samples = (int)n_samples;
                buffer.extract_dup (0, buffer.get_size (), out audio_frame.data);
                sender.send_audio_interleaved_16s (audio_frame);
                free (audio_frame.data);
                return Gst.FlowReturn.OK;
            }

            return Gst.FlowReturn.OK;
        }

        public override Gst.StateChangeReturn change_state (Gst.StateChange transition) {
            switch (transition) {
                case Gst.StateChange.READY_TO_PAUSED:
                    collect.start ();
                    break;
                case Gst.StateChange.PAUSED_TO_READY:
                    collect.stop ();
                    break;
                default:
                    break;
            }

            return base.change_state (transition);
        }

        public bool handle_event (Gst.Base.CollectPads pads, Gst.Base.CollectData data, Gst.Event event) {
            bool ret = true;

            switch (event.type) {
                case Gst.EventType.CAPS:
                    Gst.Caps caps;
                    event.parse_caps (out caps);
                    if (data.pad.name.has_prefix ("video")) {
                        ret = vidsink_set_caps (caps);
                    } else {
                        ret = audsink_set_caps (caps);
                    }

                    event = null;

                    break;
                default:
                    break;
            }

            if (event != null) {
                return collect.event_default (data, event, false);
            }

            return ret;
        }

        public override Gst.Pad? request_pad (Gst.PadTemplate tmpl, string? req_name, Gst.Caps? caps) {
            if (tmpl.direction != Gst.Pad.SINK) {
                warning ("ndisink: Received a request for a pad that is not a SINK pad");
                return null;
            }

            int pad_id = -1;
            string? pad_name = null;

            if (tmpl == get_pad_template ("audio_%u")) {
                if (req_name != null && req_name.scanf ("audio_%u", &pad_id) == 1) {
                    pad_name = req_name;
                } else {
                    pad_name = "audio_%u".printf (audio_pads++);
                }
            } else if (tmpl == get_pad_template ("video_%u")) {
                if (video_pads > 0) {
                    warning ("ndisink: Can only have one video pad");
                    return null;
                }

                pad_name = "video_0";
                video_pads++;
            } else {
                warning ("ndisink: This is not a pad template we support!");
                return null;
            }

            var newpad = new Gst.Pad.from_template (tmpl, pad_name);
            var collect_data = collect.add_pad (newpad, (uint)sizeof (Gst.Base.CollectData), null, true);

            if (collect_data == null) {
                warning ("ndisink: Unable to add new pad to CollectPad");
                return null;
            }

            if (!add_pad (newpad)) {
                warning ("ndisink: Unable to add pad to element");
                return null;
            }

            return newpad;
        }

        public bool audsink_set_caps (Gst.Caps caps) {
            warning (caps.to_string ());

            unowned Gst.Structure struc = caps.get_structure (0);
            int channels, rate;

            if (!struc.get_int ("channels", out channels)) {
                return false;
            }

            if (!struc.get_int ("rate", out rate)) {
                return false;
            }

            audio_frame.sample_rate = rate;
            audio_frame.no_channels = channels;

            return true;
        }

        public bool vidsink_set_caps (Gst.Caps caps) {
            warning (caps.to_string ());

            unowned Gst.Structure struc = caps.get_structure (0);
            int width, height, frame_rate_n, frame_rate_d;
            if (!struc.get_int ("width", out width)) {
                return false;
            }

            if (!struc.get_int ("height", out height)) {
                return false;
            }

            if (struc.get_fraction ("framerate", out frame_rate_n, out frame_rate_d)) {
                video_frame.frame_rate_N = frame_rate_n;
                video_frame.frame_rate_D = frame_rate_d;
            }

            var format = struc.get_string ("format");
            if (format == null) {
                return false;
            }

            switch (format) {
                case "BGRA":
                    video_frame.pixel_format = NDI.FourCCPixelFormat.BGRA;
                    video_frame.line_stride_in_bytes = width * 4;
                    video_buffer_size = width * height * 4;
                    break;
                case "BGRx":
                    video_frame.pixel_format = NDI.FourCCPixelFormat.BGRX;
                    video_frame.line_stride_in_bytes = width * 4;
                    video_buffer_size = width * height * 4;
                    break;
                case "RGBA":
                    video_frame.pixel_format = NDI.FourCCPixelFormat.RGBA;
                    video_frame.line_stride_in_bytes = width * 4;
                    video_buffer_size = width * height * 4;
                    break;
                case "RGBx":
                    video_frame.pixel_format = NDI.FourCCPixelFormat.RGBX;
                    video_frame.line_stride_in_bytes = width * 4;
                    video_buffer_size = width * height * 4;
                    break;
                case "I420":
                    video_frame.pixel_format = NDI.FourCCPixelFormat.I420;
                    video_frame.line_stride_in_bytes = width;
                    video_buffer_size = width * height * 3;
                    break;
                case "NV12":
                    video_frame.pixel_format = NDI.FourCCPixelFormat.NV12;
                    video_frame.line_stride_in_bytes = width;
                    video_buffer_size = width * height * 3;
                    break;
                case "UYVY":
                    video_frame.pixel_format = NDI.FourCCPixelFormat.UYVY;
                    video_frame.line_stride_in_bytes = width * 2;
                    video_buffer_size = width * height * 2;
                    break;
                case "YV12":
                    video_frame.pixel_format = NDI.FourCCPixelFormat.YV12;
                    video_frame.line_stride_in_bytes = width;
                    video_buffer_size = width * height * 2;
                    break;
                default:
                    return false;
            }

            video_frame.xres = width;
            video_frame.yres = height;

            if (video_frame.data != null) {
                free (video_frame.data);
            }

            return true;
        }
    }
}

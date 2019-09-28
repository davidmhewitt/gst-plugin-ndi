[CCode (cheader_filename="Processing.NDI.Lib.h", lower_case_cprefix="NDIlib_")]
namespace NDI {
    public static bool initialize ();
    public static void destroy ();

    [Compact]
    [CCode (cname="void", free_function="NDIlib_send_destroy", lower_case_cprefix="NDIlib_send_")]
    public class Send {
        [CCode (cname="NDIlib_send_timecode_synthesize")]
        public const int64 TIMECODE_SYNTHESIZE;

        [CCode (cname="NDIlib_send_create_t", has_type_id=false)]
        public struct Options {
            [CCode (cname="p_ndi_name")]
            string? name;
            [CCode (cname="p_groups")]
            string? groups;
            bool clock_video;
            bool clock_audio;
        }

        public static Send? create (Options options = {null, null, true, true});

        public void send_video_v2 (VideoFrameV2 frame);
    }

    [CCode (cname="NDIlib_video_frame_v2_t", destroy_function="")]
    public struct VideoFrameV2 {
        int xres;
        int yres;
        [CCode (cname="FourCC")]
        FourCCPixelFormat pixel_format;
        int frame_rate_N;
        int frame_rate_D;
        float picture_aspect_ratio;
        [CCode (cname="frame_format_type")]
        VideoFrameFormat type;
        int64 timecode;
        [CCode (cname="p_data", array_length=false)]
        uint8* data;
        int line_stride_in_bytes;
        int data_size_in_bytes;
        [CCode (cname="p_metadata")]
        string? metadata;
        int64 timestamp;

        public static VideoFrameV2 create_default () {
            return VideoFrameV2 () {
                xres = 0,
                yres = 0,
                pixel_format = FourCCPixelFormat.UYVY,
                frame_rate_N = 30000,
                frame_rate_D = 1001,
                picture_aspect_ratio = 0.0f,
                type = VideoFrameFormat.PROGRESSIVE,
                timecode = Send.TIMECODE_SYNTHESIZE,
                data = null,
                line_stride_in_bytes = 0,
                metadata = null,
                timestamp = 0
            };
        }
    }

    [CCode (cname="NDIlib_FourCC_video_type_e", cprefix="NDIlib_FourCC_type_")]
    public enum FourCCPixelFormat {
        UYVY,
        UYVA,
        P216,
        PA16,
        YV12,
        I420,
        NV12,
        BGRA,
        BGRX,
        RGBA,
        RGBX
    }

    [CCode (cname="NDIlib_frame_format_type_e")]
    public enum VideoFrameFormat {
        [CCode (cname="NDIlib_frame_format_type_progressive")]
        PROGRESSIVE,
        [CCode (cname="NDIlib_frame_format_type_interleaved")]
        INTERLEAVED,
        [CCode (cname="NDIlib_frame_format_type_field_0")]
        FIELD0,
        [CCode (cname="NDIlib_frame_format_type_field_1")]
        FIELD1
    }
}

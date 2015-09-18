package assets
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;

	//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
	//  Events
	//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
	
	[Event(name="complete", type="flash.events.Event")]
	[Event(name="error", type="flash.events.ErrorEvent")]
	
	/**
	 * ffmpeg 封装成转换视频格式的类。
	 * 
	 * @example 食用方法：
	 * <listing version="3.0">
		const ffmpeg:FFMPEG = new FFMPEG(File.applicationDirectory.resolvePath('assets/ffmpeg.exe'));
		ffmpeg.addEventListener(NativeProcessExitEvent.EXIT, function(event:Event):void
		{
				trace('complete');
		});
		ffmpeg.convert('C:/Users/Administrator/Desktop/_hard_renaissayaka_wav/_hard_renaissayaka_wav/_bga.mpg',
		'C:/Users/Administrator/Desktop/_bga.mp4');
	 * </listing>
	 */
	public class FFMPEG extends NativeProcess
	{
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Class constants
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		private static const RE_OVERWRITE:RegExp =
			/File '[^']*' already exists\. Overwrite \? \[y\/N\]/i;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Constructor
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function FFMPEG(file:File)
		{
			// 设置要启动的文件。
			info = new NativeProcessStartupInfo();
			info.executable = file;
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Variables
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆

		private var info:NativeProcessStartupInfo;
		
		private var stdout:String;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Methods
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function convert(src:String, dst:String):void
		{
			// 设置要启动的文件，参数。
			info.arguments = new <String>[
				'-i', src, dst
			];
			
			// 如果目标的目录没有创建，就无法转换，所以得先创建目录。
			const dstDir:File = new File(dst).resolvePath('..');
			if (!dstDir.exists)
			{
				dstDir.createDirectory();
			}
			
			stdout = '';
			addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			addEventListener(NativeProcessExitEvent.EXIT, onExit);
			start(info);
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Event handlers
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		/**
		 * 它只 error，什么鬼东西。
		 */
		private function onErrorData(event:ProgressEvent):void
		{
			const newStdout:String = standardError.readUTFBytes(standardError.bytesAvailable);
			stdout += newStdout;
			
			// 强制覆盖。是否覆盖不在这儿判断，在 Beatmap 里。
			if (RE_OVERWRITE.test(stdout))
			{
				standardInput.writeUTFBytes('y\n');
				removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, arguments.callee);
			}
		}
		
		private function onExit(event:NativeProcessExitEvent):void
		{
			removeEventListener(NativeProcessExitEvent.EXIT, arguments.callee);
			
			if (event.exitCode == 0)
			{
				dispatchEvent(new Event(Event.COMPLETE));
			}
			else
			{
				dispatchEvent(new ErrorEvent(ErrorEvent.ERROR));
			}
		}
	}
}


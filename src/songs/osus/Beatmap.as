package songs.osus
{
	import assets.FFMPEG;
	import errors.BMSError;
	import events.BMSEvent;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import moe.aoi.utils.FileReferenceUtil;
	import songs.bmses.BMS;
	import songs.bmses.BMSPack;
	import workers.BackgroundWorker;

	//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
	//  Events
	//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
	
	[Event(name="copying_osu", type="events.BMSEvent")]
	[Event(name="copying_wav", type="events.BMSEvent")]
	[Event(name="copying_bmp", type="events.BMSEvent")]
	[Event(name="complete", type="flash.events.Event")]
	[Event(name="ioError", type="flash.events.IOErrorEvent")]
	[Event(name="error", type="flash.events.ErrorEvent")]
	
	public final class Beatmap extends EventDispatcher
	{
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Class variables
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		private static var ffmpeg:FFMPEG = new FFMPEG(BackgroundWorker.APPLICATION_DIRECTORY.resolvePath('assets/ffmpeg.exe'));
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Constructor
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function Beatmap()
		{
			
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Variables
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public var name:String;
		
		public var bmsPack:BMSPack;
		
		private var directory:File;
		
		private var outputDirectory:File;
		
		private var osues:Vector.<OSU> = new <OSU>[];

		private var index:uint;
		
		private var wavs:Vector.<String>;
		
		private var bmps:Vector.<String>;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Methods
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function collectResources():void
		{
			wavs = new <String>[];
			bmps = new <String>[];
			
			for each (var bms:BMS in bmsPack.bmses) 
			{
				var bms_wavs:Array = bms.wavs;
				for each (var wav:String in bms_wavs) 
				{
					if (wavs.indexOf(wav) == -1)
					{
						wavs.push(wav);
					}
				}
				
				var bms_bmps:Array = bms.bmps;
				for each (var bmp:String in bms_bmps) 
				{
					if (bmps.indexOf(bmp) == -1)
					{
						bmps.push(bmp);
					}
				}
				
				var stagefile:String = bms.stagefile;
				if (stagefile && bmps.indexOf(stagefile) == -1)
				{
					bmps.push(stagefile);
				}
				
				var banner:String = bms.banner;
				if (banner && bmps.indexOf(banner) == -1)
				{
					bmps.push(banner);
				}
				
				var backbmp:String = bms.backbmp;
				if (backbmp && bmps.indexOf(backbmp) == -1)
				{
					bmps.push(backbmp);
				}
			}
		}
		
//		registerClassAlias('flash.filesystem.File', File);
		public function saveAsync(outputDir:File):void
		{
			outputDirectory = outputDir;
			// 不复制了
//			bmsPack = osues[0].bms.bmsPack;
//			const ba:ByteArray = new ByteArray();
//			ba.writeObject(bmsPack.directory);
//			ba.position = 0;
//			directory = ba.readObject();
			directory = bmsPack.directory;
			
			index = 0;
			saveOSUAsync();
		}
		
		private function saveOSUAsync():void
		{
			const osu:OSU = osues[index];
			const fs:FileStream = new FileStream();
			
			var tempFile:File;
			try // 不能放到 for each 外面，因为要单个单个处理错误。
			{
				// TODO: 这里也要异步。
				tempFile = File.createTempFile();
				fs.open(tempFile, FileMode.WRITE);
				fs.writeUTFBytes(osu.print());
				fs.close();
				
				// TODO: 确认是否覆盖。
				const dst:File = outputDirectory.resolvePath(name + '/' + FileReferenceUtil.filterName(osu.name, ' ') + '.osu');
				const nextFunc:Function = index == osues.length - 1 ? nextPhase : nextOSU;
				
				tempFile.addEventListener(Event.COMPLETE, nextFunc);
				tempFile.addEventListener(IOErrorEvent.IO_ERROR, OnIoError)
				tempFile.copyToAsync(dst, true);
				
				if (index == 0) // 第一个复制的文件名这样才会显示出来。
				{
					dispatchEvent(new BMSEvent(BMSEvent.COPYING_OSU, dst.name, index, osues.length));
				}
				
				trace('copy:', FileReferenceUtil.filterName(osu.name, ' ') + '.osu');
			} 
			catch(error:Error) 
			{
				// TODO: 提示。
				BackgroundWorker.current.sendError(new BMSError('保存文件' + name + '时出现错误', error, bmsPack.directory));
			}
			
			function nextOSU(event:Event):void
			{
				tempFile.removeEventListener(Event.COMPLETE, arguments.callee);
				tempFile.removeEventListener(IOErrorEvent.IO_ERROR, OnIoError);
				tempFile.deleteFileAsync();
				
				index++;
				dispatchEvent(new BMSEvent(BMSEvent.COPYING_OSU, dst.name, index, osues.length));
				
				saveOSUAsync();
			}
			
			function nextPhase(event:Event):void
			{
				tempFile.removeEventListener(Event.COMPLETE, arguments.callee);
				tempFile.removeEventListener(IOErrorEvent.IO_ERROR, OnIoError);
				tempFile.deleteFileAsync();
				
				index++;
				dispatchEvent(new BMSEvent(BMSEvent.COPYING_OSU, dst.name, index, osues.length));
				
				index = 0;
				dispatchEvent(new BMSEvent(BMSEvent.COPYING_WAV, null, index, wavs.length));
				saveWav();
			}
			
			function OnIoError(event:IOErrorEvent):void
			{
				tempFile.removeEventListener(Event.COMPLETE, nextOSU);
				tempFile.removeEventListener(Event.COMPLETE, nextPhase);
				tempFile.removeEventListener(IOErrorEvent.IO_ERROR, arguments.callee);
				
				dispatchEvent(event);
			}
		}
		
		private function saveWav():void
		{
			const fileName:String = wavs[index];
			
			// 以下复制自 saveFile()。
			const file:File = directory.resolvePath(BMS2OSUConverter.matchPath(fileName));
			const extension:String = file.extension;
			const dst:File = outputDirectory.resolvePath(name + '/' + BMS2OSUConverter.PREFIX_SOUND_FILE + file.name);
			
			const nextFunc:Function = index == wavs.length - 1 ?
				nextPhase : nextWav;
			
			// 其他文件复制。
			// TODO: 覆盖？
			// TODO: 判断文件不存在给提示。
			if (dst.exists)
			{
				// TODO: 检验MD5是否相同，相同即跳过。
				trace('already exists:', decodeURIComponent(dst.url)); // 让我先摆脱一下复制地狱。
				nextFunc();
				return;
			}
			
			if (!file.exists)
			{
				trace('not exists:', decodeURIComponent(dst.url));
				nextFunc();
				return;
			}
			
			trace('save:', decodeURIComponent(dst.url));
			
			file.addEventListener(Event.COMPLETE, nextFunc);
			file.addEventListener(IOErrorEvent.IO_ERROR, OnIoError);
			file.copyToAsync(dst, true);
			
			if (index == 0) // 第一个复制的文件名这样才会显示出来。
				dispatchEvent(new BMSEvent(BMSEvent.COPYING_WAV, dst.name, index, wavs.length));
			
			function nextWav(event:Event = null):void
			{
				file.removeEventListener(Event.COMPLETE, arguments.callee);
				file.removeEventListener(IOErrorEvent.IO_ERROR, OnIoError);
				dispatchEvent(new Event(ProgressEvent.PROGRESS));
				
				index++;
				dispatchEvent(new BMSEvent(BMSEvent.COPYING_WAV, dst.name, index, wavs.length));
				
				saveWav();
			}
			
			function nextPhase(event:Event = null):void
			{
				file.removeEventListener(Event.COMPLETE, arguments.callee);
				file.removeEventListener(IOErrorEvent.IO_ERROR, OnIoError);
				
				index++;
				dispatchEvent(new BMSEvent(BMSEvent.COPYING_WAV, dst.name, index, wavs.length));
				
				index = 0;
				dispatchEvent(new BMSEvent(BMSEvent.COPYING_BMP, null, index, bmps.length));
				saveBmp();
			}
			
			function OnIoError(event:IOErrorEvent):void
			{
				file.removeEventListener(Event.COMPLETE, nextWav);
				file.removeEventListener(Event.COMPLETE, nextPhase);
				file.removeEventListener(IOErrorEvent.IO_ERROR, arguments.callee);
				
				dispatchEvent(event);
			}
		}
		
		private function saveBmp():void
		{
			const fileName:String = bmps[index];
			
			const file:File = directory.resolvePath(BMS2OSUConverter.matchPath(fileName));
			const extension:String = file.extension;
			
			const nextFunc:Function = index == bmps.length - 1 ?
				complete : nextBmp;
			
			var dst:File;
			
			// bga 复制。
			if (extension == 'mpg'
			||  extension == 'mpeg') // 如果是 mpg 格式的 bga，转换。
				dst = outputDirectory.resolvePath(name + '/' + BMS2OSUConverter.PREFIX_BMP_FILE +
					FileReferenceUtil.getBaseName(file) + BMS2OSUConverter.FORMAT_CONVERT);
			else
				dst = outputDirectory.resolvePath(name + '/' + BMS2OSUConverter.PREFIX_BMP_FILE + file.name);
			
			// 其他文件复制。
			// TODO: 覆盖？
			// TODO: 判断文件不存在给提示。
			if (dst.exists)
			{
				// TODO: 检验MD5是否相同，相同即跳过。
				trace('already exists:', decodeURIComponent(dst.url)); // 让我先摆脱一下复制地狱。
				nextFunc();
				return;
			}
			
			if (!file.exists)
			{
				trace('not exists:', decodeURIComponent(dst.url));
				nextFunc();
				return;
			}
			
			trace('save:', decodeURIComponent(dst.url));
			
			if (extension == 'mpg'
			||  extension == 'mpeg')
			{
				// TODO: 写成字段看看会不会出错。
				ffmpeg.addEventListener(Event.COMPLETE, nextFunc);
				ffmpeg.addEventListener(ErrorEvent.ERROR, onError);
				// TODO: try。
				ffmpeg.convert(file.nativePath, dst.nativePath); // 用 url 不行，它不认。
			}
			else
			{
				file.addEventListener(Event.COMPLETE, nextFunc);
				file.addEventListener(IOErrorEvent.IO_ERROR, OnIoError);
				file.copyToAsync(dst, true);
			}
			
			if (index == 0) // 第一个复制的文件名这样才会显示出来。
				dispatchEvent(new BMSEvent(BMSEvent.COPYING_BMP, dst.name, index, bmps.length));
			
			function nextBmp(event:Event = null):void
			{
				file.removeEventListener(Event.COMPLETE, arguments.callee);
				file.removeEventListener(ErrorEvent.ERROR, onError);
				file.removeEventListener(IOErrorEvent.IO_ERROR, OnIoError);
				
				index++;
				dispatchEvent(new BMSEvent(BMSEvent.COPYING_BMP, dst.name, index, bmps.length));
				
				saveBmp();
			}
			
			function complete(event:Event = null):void
			{
				file.removeEventListener(Event.COMPLETE, arguments.callee);
				file.removeEventListener(ErrorEvent.ERROR, onError);
				file.removeEventListener(IOErrorEvent.IO_ERROR, OnIoError);
				
				index++;
				dispatchEvent(new BMSEvent(BMSEvent.COPYING_BMP, dst.name, index, bmps.length));
				
				dispatchEvent(event || new Event(Event.COMPLETE));
			}
			
			function onError(event:ErrorEvent):void
			{
				file.removeEventListener(Event.COMPLETE, nextBmp);
				file.removeEventListener(Event.COMPLETE, complete);
				file.removeEventListener(ErrorEvent.ERROR, arguments.callee);
				
				dispatchEvent(event);
			}
			
			function OnIoError(event:IOErrorEvent):void
			{
				file.removeEventListener(Event.COMPLETE, nextBmp);
				file.removeEventListener(Event.COMPLETE, complete);
				file.removeEventListener(IOErrorEvent.IO_ERROR, arguments.callee);
				
				dispatchEvent(event);
			}
		}
		
//		private function saveFiles(event):void
//		{
//			// 把函数放 in 后面看看会不会被多次调用。
//			const wavs:Vector.<String> = res.wavs;
//			const bmps:Vector.<String> = res.bmps;
//			
//			for each (var wav:String in wavs) 
//			{
//				saveFile(wav, BMS2OSUConverter.PREFIX_SOUND_FILE);
//			}
//			
//			for each (var bmp:String in bmps) 
//			{
//				saveFile(bmp, BMS2OSUConverter.PREFIX_BMP_FILE);
//			}
//		}
		
//		private function saveFile(fileName:String, path:String):void
//		{
//			const file:File = directory.resolvePath(BMS2OSUConverter.matchPath(fileName));
//			const extension:String = file.extension;
//			var dst:File;
//			
//			// bga 复制。
//			if (extension == 'mpg'
//			||  extension == 'mpeg') // 如果是 mpg 格式的 bga，转换。
//				dst = outputDirectory.resolvePath(name + '/' + path + FileReferenceUtil.getBaseName(file) + BMS2OSUConverter.FORMAT_CONVERT);
//			else
//				dst = outputDirectory.resolvePath(name + '/' + path + file.name);
//			
//			// 其他文件复制。
//			// TODO: 覆盖？
//			// TODO: 判断文件不存在给提示。
//			if (dst.exists)
//			{
//				// TODO: 检验MD5是否相同，相同即跳过。
//				trace('already exists:', decodeURIComponent(dst.url)); // 让我先摆脱一下复制地狱。
//				return;
//			}
//			
//			if (!file.exists)
//			{
//				trace('not exists:', decodeURIComponent(dst.url));
//				return;
//			}
//			
//			trace('save:', decodeURIComponent(dst.url));
//			
//			if (extension == 'mpg'
//			||  extension == 'mpeg')
//			{
//				const ffmpeg:FFMPEG = new FFMPEG(File.applicationDirectory.resolvePath('assets/ffmpeg.exe'));
//				ffmpeg.addEventListener(NativeProcessExitEvent.EXIT, function(event:Event):void
//				{
//					trace(decodeURIComponent(dst.nativePath), ': convert complete');
//				});
//				ffmpeg.convert(file.nativePath, dst.nativePath); // 用 url 不行，它不认。
//			}
//			else
//			{
//				try
//				{
//					file.copyTo(dst, true);
//				} 
//				catch(error:Error) 
//				{
//					trace(error);
//					trace('我就不信了，再试一次');
//					file.copyTo(dst, true);
//				}
//			}
//		}
		
		internal function addOSU(osu:OSU):void
		{
			osues.push(osu);
		}
	}
}


package songs.osus
{
	import flash.events.Event;
	import flash.events.NativeProcessExitEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.registerClassAlias;
	import flash.utils.ByteArray;
	
	import assets.FFMPEG;
	
	import moe.aoi.utils.FileReferenceUtil;
	
	import songs.bmses.BMS;
	import songs.bmses.BMSPack;

	public final class Beatmap
	{
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
		
		private var directory:File;
		
		private var outputDirectory:File;
		
		private var osues:Vector.<OSU> = new <OSU>[];
		
		private var bmsPack:BMSPack;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Methods
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		registerClassAlias('flash.filesystem.File', File);
		public function saveAsync(outputDir:File):void
		{
			outputDirectory = outputDir;
			bmsPack = osues[0].bms.bmsPack;
			var ba:ByteArray = new ByteArray();
			ba.writeObject(bmsPack.directory);
			ba.position = 0;
			directory = ba.readObject();
			
			saveOSUesAsync();
			saveFiles();
		}
		
		private function saveOSUesAsync():void
		{
			var fs:FileStream = new FileStream();
			
			for each (var osu:OSU in osues) 
			{
				try // 不能放到 for each 外面，因为要单个单个处理错误。
				{
					var tempFile:File = File.createTempFile();
					fs.open(tempFile, FileMode.WRITE);
					fs.writeUTFBytes(osu.print());
					fs.close();
					
					// TODO: 确认是否覆盖。
					var dst:File = outputDirectory.resolvePath(name + '/'
						+ FileReferenceUtil.filterName(osu.name, ' ') + '.osu');
					tempFile.copyTo(dst, true);
					tempFile.deleteFileAsync();
				} 
				catch(error:Error) 
				{
					// TODO: 提示。
					throw error;
				}
			}
		}
		
		private function saveFiles():void
		{
			// 把函数放 in 后面看看会不会被多次调用。
 			const res:Object = collectResources();
			const wavs:Vector.<String> = res.wavs;
			const bmps:Vector.<String> = res.bmps;
			
			for each (var wav:String in wavs) 
			{
				saveFile(wav, BMS2OSUConverter.PREFIX_SOUND_FILE);
			}
			
			for each (var bmp:String in bmps) 
			{
				saveFile(bmp, BMS2OSUConverter.PREFIX_BMP_FILE);
			}
		}
		
		private function saveFile(fileName:String, path:String):void
		{
			const file:File = directory.resolvePath(BMS2OSUConverter.matchPath(fileName));
			const extension:String = file.extension;
			var dst:File;
			
			// bga 复制。
			if (extension == 'mpg'
			||  extension == 'mpeg') // 如果是 mpg 格式的 bga，转换。
				dst = outputDirectory.resolvePath(name + '/' + path + FileReferenceUtil.getBaseName(file) + BMS2OSUConverter.FORMAT_CONVERT);
			else
				dst = outputDirectory.resolvePath(name + '/' + path + file.name);
			
			// 其他文件复制。
			// TODO: 覆盖？
			// TODO: 判断文件不存在给提示。
			if (dst.exists)
			{
				// TODO: 检验MD5是否相同，相同即跳过。
				trace('already exists:', decodeURIComponent(dst.url)); // 让我先摆脱一下复制地狱。
				return;
			}
			
			if (!file.exists)
			{
				trace('not exists:', decodeURIComponent(dst.url));
				return;
			}
			
			trace('save:', decodeURIComponent(dst.url));
			
			if (extension == 'mpg'
			||  extension == 'mpeg')
			{
				const ffmpeg:FFMPEG = new FFMPEG(File.applicationDirectory.resolvePath('assets/ffmpeg.exe'));
				ffmpeg.addEventListener(NativeProcessExitEvent.EXIT, function(event:Event):void
				{
					trace(decodeURIComponent(dst.nativePath), ': convert complete');
				});
				ffmpeg.convert(file.nativePath, dst.nativePath); // 用 url 不行，它不认。
			}
			else
			{
				try
				{
					file.copyTo(dst, true);
				} 
				catch(error:Error) 
				{
					trace(error);
					trace('我就不信了，再试一次');
					file.copyTo(dst, true);
				}
			}
		}
		
		private function collectResources():Object
		{
			const wavs:Vector.<String> = new <String>[];
			const bmps:Vector.<String> = new <String>[];
			for each (var bms:BMS in bmsPack.bmses) 
			{
				var bms_wavs:Array = bms.wavs;
				for each (var wav:String in bms_wavs) 
				{
					if (wavs.indexOf(wav) === -1)
						wavs.push(wav);
				}
				
				var bms_bmps:Array = bms.bmps;
				for each (var bmp:String in bms_bmps) 
				{
					if (bmps.indexOf(bmp) === -1)
						bmps.push(bmp);
				}
				
				var stagefile:String = bms.stagefile;
				if (stagefile)
					bmps.push(stagefile);
				
				var banner:String = bms.banner;
				if (banner)
					bmps.push(banner);
				
				var backbmp:String = bms.backbmp;
				if (backbmp)
					bmps.push(backbmp);
			}
			
			return {wavs: wavs, bmps: bmps};
		}
		
		internal function addOSU(osu:OSU):void
		{
			osues.push(osu);
		}
	}
}


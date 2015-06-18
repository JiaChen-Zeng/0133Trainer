package songs.bmses
{
	import moe.aoi.utils.FileReferenceUtil;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.FileListEvent;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	
	import mx.utils.StringUtil;

	//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
	//  Events
	//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
	
	[Event(name="complete", type="flash.events.Event")]
	[Event(name="ioError", type="flash.events.IOErrorEvent")]
	
	public final class BMSPack extends EventDispatcher implements IBMS
	{
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Class constants
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public static const RE_VERSION:RegExp = /\(.+\)|\[.+\]|-.+-$/;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Constructor
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function BMSPack()
		{
			
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Variables
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		private var encoding:String;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Properties
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		private var _bmses:Vector.<BMS>;
		
		public function get bmses():Vector.<BMS> { return _bmses; }
		
		private var _name:String;
		
		public function get name():String { return _name; }
		
		private var _directory:File;
		
		public function get directory():File { return _directory; }
		
		private var _processingFiles:Vector.<File>;
		
		public function get processingFiles():Vector.<File> { return _processingFiles; }
		
		private var _completedFiles:Vector.<File>;
		
		public function get completedFiles():Vector.<File> { return _completedFiles; }
		
		private var _failedEvents:Vector.<IOErrorEvent>;
		
		public function get failedEvents():Vector.<IOErrorEvent> { return _failedEvents; }
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Methods
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function load(directory:File, encoding:String):void
		{
			_directory = directory;
			
			this.encoding = encoding;
			
			loadBMSes();
		}
		
		private function loadBMSes():void
		{
			// TODO: 加载文件夹内所有 BMS。
			_bmses 				= new <BMS>[];
			_processingFiles	= new <File>[];
			_completedFiles		= new <File>[];
			_failedEvents		= new <IOErrorEvent>[];
			
			_directory.addEventListener(FileListEvent.DIRECTORY_LISTING, directory_listingHandler);
			_directory.getDirectoryListingAsync();
		}
		
		private function directory_listingHandler(event:FileListEvent):void
		{
			var files:Array = event.files;
			for each (var file:File in files) 
			{
				if (!BMS.isBMS(file))
					continue;
				
				trace("BMSPack.directory_directoryListingHandler(event) : ",
					file.name);
				_processingFiles.push(file);
				file.addEventListener(Event.COMPLETE, file_completeHandler);
				file.addEventListener(IOErrorEvent.IO_ERROR, file_IoErrorHandler);
				file.load();
			}
		}
		
		private function file_completeHandler(event:Event):void
		{
			trace('file loaded');
			var file:File = event.currentTarget as File;
			file.removeEventListener(Event.COMPLETE, arguments.callee);
			
			// TODO: 选择转什么码，自动转码。
			var bms:BMS = new BMS(this);
			bms.name = FileReferenceUtil.getBaseName(file);
			bms.setData(file.data, encoding);
			bms.load();
			_bmses.push(bms);
//			trace('loadComplete');
			
			_processingFiles.splice(_processingFiles.indexOf(file), 1);
			_completedFiles.push(file);
			if (_processingFiles.length === 0)
				matchName();
			dispatchEvent(event);
		}
		
		
		private function file_IoErrorHandler(event:IOErrorEvent):void
		{
			_processingFiles.splice(_processingFiles.indexOf(event.target), 1);
			_failedEvents.push(event);
			dispatchEvent(event);
		}
		
		private function matchName():void
		{
			// TODO: 根据匹配出的难度名猜测是否为难度名。
			// 模糊匹配关键字 {n}key、light、nomal、hard、hyper、another 等等。
			try
			{
				// ==========取得全部标题。==========
				var longTitles:Vector.<String> = new <String>[];
				for each (var bms:BMS in bmses) 
				{
					longTitles.push(bms.title);
				}
				var length:uint = longTitles.length;
				
				// ==========判断是否有谱没难度名。==========
				// 因为如果没有难度名，取最后框上的难度名的话可能会误取到歌名里的框。
				// 假设有难度名。
				var allHaveVersion:Boolean = true;
				var versions:Vector.<String> = new <String>[];
				var titles:Vector.<String> = new <String>[];
				for each (var longTitle:String in longTitles) 
				{
					var version:String = RE_VERSION.exec(longTitle);
					
					titles.push(StringUtil.trim(longTitle.replace(version, '')));
					versions.push(version);
				}
				
				// ==========这里不是完全确定，还有可能是取到了歌名里的框。==========
				// 计算出每个谱是正确歌名的概率。
				var probability:Vector.<Number> = new <Number>[];
				for (var i:int = 0; i < length; i++) 
				{
					probability[i] = 0;
					for (var j:int = 0; j < length; j++) 
					{
						// 自己和别人比较，自己和自己就算了。
						if (i === j)
							continue;
						
						if (titles[i] === titles[j])
							probability[i]++;
					}
					
					// TODO: 如果就自己一个呢？貌似问题是没有的。
					probability[i] /= length - 1; // 得减去自己。
				}
				
				// ==========如果取到的歌名都是一样的（100%），那么就是它了。==========
				for (var i3:int = 0; i3 < length; i3++) 
				{
					if (probability[i3] === 1.00)
					{
						_name = titles[0];
						return;
					}
				}
				
				// ==========没那么幸运，取跟最多谱子一样的标题。==========
				var maxProbability:Number;
				var maxProbabilityIndex:uint;
				for (var k:int = 0; k < length; k++) 
				{
					for (var i4:int = k + 1; i4 < length; i4++) 
					{
						var p1:Number = probability[k];
						var p2:Number = probability[i4];
						
						if (p1 > p2)
						{
							maxProbability = p1;
							maxProbabilityIndex = k;
						}
						else
						{
							maxProbability = p2;
							maxProbabilityIndex = i4;
						}
					}
				}
				
				// 很多（70%以上）歌名都不一样，那么应该是混合歌包。
				if (maxProbability < 70)
					_name = titles[maxProbabilityIndex];
			} 
			catch(error:Error) 
			{
//				throw error;
				trace('匹配难度名出现错误，可能出现了乱码：' + bmses[0].title);
			}
		}
	}
}



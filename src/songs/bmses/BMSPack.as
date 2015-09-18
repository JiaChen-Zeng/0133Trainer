package songs.bmses
{
	import events.BMSEvent;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.FileListEvent;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import models.Config;
	import moe.aoi.utils.FileReferenceUtil;
	import mx.utils.StringUtil;
	import errors.BMSError;

	//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
	//  Events
	//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
	
	[Event(name="complete", type="flash.events.Event")]
	[Event(name="ioError", type="flash.events.IOErrorEvent")]
	[Event(name="error", type="flash.events.ErrorEvent")]
	[Event(name="collecting", type="events.BMSEvent")]
	[Event(name="collected", type="events.BMSEvent")]
	[Event(name="loading", type="events.BMSEvent")]
	[Event(name="loaded", type="events.BMSEvent")]
	[Event(name="parsing", type="events.BMSEvent")]
	[Event(name="parsed", type="events.BMSEvent")]
	
	/**
	 * 装着 bms 的文件夹用这个类表示。
	 */
	public final class BMSPack extends EventDispatcher implements IBMS
	{
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Class constants
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		/** 这个好像是匹配出难度名？ */
		public static const RE_VERSION:RegExp = /\(.+\)|\[.+\]|-.+-$/;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Constructor
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function BMSPack(directory:File, config:Config)
		{
			_directory = directory;
			this.config = config;
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Variables
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		private var config:Config;
		
		private var currentIndex:uint;
		
		private var total:uint;
		
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
		
		private var _collectedFiles:Vector.<File>;
		
		public function get processingFiles():Vector.<File> { return _collectedFiles; }
		
		private var _loadedFiles:Vector.<File>;
		
		public function get loadedFiles():Vector.<File> { return _loadedFiles; }
		
		private var _parsedFiles:Vector.<File>;
		
		public function get completedFiles():Vector.<File> { return _parsedFiles; }
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Methods
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		/**
		 * 初始化，收集所有在 BMSPack 文件夹根目录的 bms 文件。
		 * 事件：BMSEvent.COLLECTING BMSEvent.COLLECTED ErrorEvent.Error 
		 */
		public function collectAll():void
		{
			_bmses 			= new <BMS>[];
			_collectedFiles	= new <File>[];
			
			_directory.addEventListener(FileListEvent.DIRECTORY_LISTING, collect);
			_directory.addEventListener(IOErrorEvent.IO_ERROR, error);
			_directory.getDirectoryListingAsync();
			
			function collect(event:FileListEvent):void
			{
				_directory.removeEventListener(FileListEvent.DIRECTORY_LISTING, collect);
				_directory.removeEventListener(IOErrorEvent.IO_ERROR, error);
				
				const files:Array = event.files;
				
				dispatchEvent(new BMSEvent(BMSEvent.COLLECTING, null, _collectedFiles.length));
				
				for each (var file:File in files) 
				{
					if (!BMS.isBMS(file))
						continue;
					
					trace("BMSPack.directory_directoryListingHandler(event) : ", file.name);
					_collectedFiles.push(file);
					
					dispatchEvent(new BMSEvent(BMSEvent.COLLECTING, file.name, _collectedFiles.length));
				}
				
				dispatchEvent(new BMSEvent(BMSEvent.COLLECTED, null, _collectedFiles.length, _collectedFiles.length));
			}
			
			function error(event:IOErrorEvent):void 
			{
				_directory.removeEventListener(FileListEvent.DIRECTORY_LISTING, collect);
				_directory.removeEventListener(IOErrorEvent.IO_ERROR, error);

				dispatchEvent(event);
			}
		}
		
		/**
		 * 加载所有收集到的 BMS。
		 * 事件：BMSEvent.LOADING BMSEvent.LOADING BMSEvent.LOADED IOErrorEvent.IO_ERROR
		 */
		public function loadAll():void
		{
			trace( "BMSPack.loadAll" );
			_loadedFiles = new <File>[];
			
			addEventListeners();
			
			currentIndex = 0;
			
			dispatchEvent(new BMSEvent(BMSEvent.LOADING, _collectedFiles[currentIndex].name, currentIndex, _collectedFiles.length));
			
			load();
			
			function load():void 
			{
				_collectedFiles[currentIndex].load();
			}
			
			function onComplete(event:Event):void
			{
				trace( "BMSPack.onComplete > event : " + event );
				const file:File = _collectedFiles[currentIndex];
				
				file.removeEventListener(Event.COMPLETE, onComplete);
				file.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);
				
				_loadedFiles.push(file);
				
				if (currentIndex == _collectedFiles.length - 1) // 可以忽略文件，不用 length
				{
					// 这里显示的是最后一个文件
					dispatchEvent(new BMSEvent(BMSEvent.LOADED, null, currentIndex, _collectedFiles.length));
				}
				else
				{
					currentIndex++; // 这里显示的是下一个文件
					dispatchEvent(new BMSEvent(BMSEvent.LOADING, _collectedFiles[currentIndex].name, currentIndex, _collectedFiles.length));
					load();
				}
				
			}
			
			function onIoError(event:IOErrorEvent):void
			{
				dispatchEvent(event);
			}
			
			function addEventListeners():void 
			{
				for each (var file:File in _collectedFiles) 
				{
					file.addEventListener(Event.COMPLETE, onComplete);
					file.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
				}
			}
		}
		
		/**
		 * 解析 bms，这儿开始就是同步的了。
		 * 事件：BMSEvent.PARSING BMSEvent.PARSED
		 */
		public function parseAll():void
		{
			_parsedFiles = new <File>[];

			currentIndex = 0;
			
			dispatchEvent(new BMSEvent(BMSEvent.PARSING, _loadedFiles[currentIndex].name, _parsedFiles.length, _loadedFiles.length));
			
			parse.call(this);
			
			function parse():void
			{
				const file:File = _loadedFiles[currentIndex];
				
				const bms:BMS = new BMS(this);
				bms.name = FileReferenceUtil.getBaseName(file);
				bms.extension = file.extension;
				bms.setData(file.data, config.encoding);
				bms.parse();
				
				_bmses.push(bms);
				_parsedFiles.push(file);
				
	//			trace('loadComplete');
				
				// TODO: 如果忽略触发 ignored 事件，前进一个进度
				if (currentIndex == _loadedFiles.length - 1) // 不比较两个 length，因为可以忽略文件
				{
					try 
					{
						matchName();
					}
					catch (error:Error)
					{
						throw new BMSError(BMSError.MATCHNAME_ERROR, error);
					}
					
					dispatchEvent(new BMSEvent(BMSEvent.PARSED, null, currentIndex, _loadedFiles.length));
				}
				else 
				{
					currentIndex++;
					dispatchEvent(new BMSEvent(BMSEvent.PARSING, _loadedFiles[currentIndex].name, currentIndex, _loadedFiles.length));
					parse.call(this);
				}
			}
		}
		
		/**
		 * 匹配出难度名。
		 */
		private function matchName():void
		{
			// TODO: 根据匹配出的难度名猜测是否为难度名。
			// 模糊匹配关键字 {n}key、light、nomal、hard、hyper、another 等等。
			//try
			//{
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
			{
				_name = titles[maxProbabilityIndex];
			}
			//catch(error:Error) 
			//{
////				throw error;
				//trace('匹配难度名出现错误，可能出现了乱码：' + bmses[0].title);
			//}
		}
	}
}


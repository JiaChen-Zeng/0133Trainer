package workers 
{
	import flash.display.Sprite;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.FileListEvent;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.net.registerClassAlias;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	
	import events.BMSEvent;
	
	import models.Config;
	
	import songs.bmses.BMS;
	import songs.bmses.BMSPack;
	import songs.osus.BMS2OSUConverter;
	import songs.osus.Beatmap;
	
	
	public final class BackgroundWorker extends Sprite
	{
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Class constants
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
//		/** 主 Worker 发送转换请求，。 */
//		public static const HEAD_READY:String = 'ready';
		
		/** 主 Worker 发送开始转换消息，开始扫描文件夹，准备转换。 */
		public static const HEAD_START:String = 'start';
		
		/** 向主 Worker 发送正在扫描文件夹的消息。 */
		public static const HEAD_COLLECTING:String = 'collecting';
		
		/** 向主 Worker 发送正在整理资源的消息。 */
		public static const HEAD_ARRANGING:String = 'arranging';
		
		/** 没有扫描到 BMS，向主 Worker 发送消息。 */
		public static const HEAD_NOT_FOUND:String = 'not_found';
		
		/** 主 Worker 里被取消，发送消息过来。 */
		public static const HEAD_CANCEL:String = 'cancel';
		
		/** 转换完毕，发送消息给主 Worker。 */
		public static const HEAD_COMPLETE:String = 'complete';
		
		/** bms 进度改变，发送消息给主 Worker。 */
		public static const HEAD_BMS_PROGRESS:String = 'bms_progress';
		
		/** bmspack 进度改变，发送消息给主 Worker。 */
		public static const HEAD_BMSPACK_PROGRESS:String = 'bmspack_progress';
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Class variables
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		/** 麻痹 AIR 的 Worker 获取到的路径会乱码，只能用 Main 获取再传过来。 */
		public static var APPLICATION_DIRECTORY:File;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Constructor
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function BackgroundWorker()
		{
			init();
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Variables
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		private var m2bChannel:MessageChannel;
		private var b2mChannel:MessageChannel;
		
		private var file:File = new File();
		private var files:Vector.<File> = new <File>[];
		
		private var processingBMSPackIndex:uint;
		
		private var bmsPacks:Vector.<BMSPack>;
		
		private var config:Config;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Methods
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		registerClassAlias('flash.filesystem.File', File);
		private function init():void
		{
			const current:Worker = Worker.current;
			
			m2bChannel = current.getSharedProperty('m2bChannel');
			b2mChannel = current.getSharedProperty('b2mChannel');
			APPLICATION_DIRECTORY = current.getSharedProperty('applicationDirectory');
			
			m2bChannel.addEventListener(Event.CHANNEL_MESSAGE, onM2BChannelMessage);
		}
		
		registerClassAlias('models.Config', Config);
		private function onM2BChannelMessage(event:Event):void
		{
			if (!m2bChannel.messageAvailable)
				return;
			
			if (m2bChannel.receive(true) == HEAD_START)
			{
				config = m2bChannel.receive(true);
				collectBMSPacks();
			}
		}
		
		/**
		 * 异步收集所有内含 BMS 的文件夹，一检测到（它里面含有 BMS）就返回，
		 * 创建对应的 BMSPack，最后收集完毕调用 loadAll()。
		 * @see #walkDirectoryAsync()
		 */
		protected function collectBMSPacks():void
		{
			b2mChannel.send(HEAD_COLLECTING);
			
			bmsPacks = new <BMSPack>[];
			
			const bmsDir:File = new File(config.bmsDirStr);
			walkDirectoryAsync(bmsDir, walkFunc, nextPhase, false);
			
			function walkFunc(file:File, dir:File):Boolean
			{
				trace("Main.walkFunc(file, dir) : ", file.name);
				if (file.isDirectory == false && BMS.isBMS(file))
				{
					bmsPacks.push(new BMSPack(dir, config));
					return true;
				}
				
				return false;
			}
			
			function nextPhase():void
			{
				if (bmsPacks.length == 0)
				{
					b2mChannel.send(HEAD_NOT_FOUND);
					return;
				}
				
				processingBMSPackIndex = 0;
				sendBMSPackProgress(bmsPacks[processingBMSPackIndex].directory.name,
					processingBMSPackIndex, bmsPacks.length);
				collectBMSes();
			}
		}
		
		protected function collectBMSes():void
		{
			const bmsPack:BMSPack = bmsPacks[processingBMSPackIndex];
			bmsPack.addEventListener(BMSEvent.COLLECTING, sendBMSProgress);
			bmsPack.addEventListener(BMSEvent.COLLECTED, loadBMSPack);
			bmsPack.addEventListener(IOErrorEvent.IO_ERROR, bmsPack_IoErrorHandler);
			
			bmsPack.collectAll();
		}
		
		/**
		 * 等到 bmsPack 收集完毕了，就一个一个开始转换。
		 */
		protected function loadBMSPack(event:BMSEvent):void
		{
			trace("Main.loadBMSPack()");
			
			const bmsPack:BMSPack = bmsPacks[processingBMSPackIndex];
			bmsPack.removeEventListener(BMSEvent.COLLECTED, arguments.callee);
			bmsPack.removeEventListener(IOErrorEvent.IO_ERROR, bmsPack_IoErrorHandler);
			bmsPack.addEventListener(BMSEvent.LOADING, sendBMSProgress);
			bmsPack.addEventListener(BMSEvent.LOADED, parseBMSPack);
			
			bmsPack.loadAll();
		}
		
		protected function parseBMSPack(event:BMSEvent):void
		{
			trace("Main.parseBMSPack(event)");
			const bmsPack:BMSPack = event.currentTarget as BMSPack;
			bmsPack.removeEventListener(BMSEvent.LOADED, arguments.callee);
			bmsPack.addEventListener(BMSEvent.PARSING, sendBMSProgress);
			bmsPack.addEventListener(BMSEvent.PARSED, convertBMSPack);
			
			bmsPack.parseAll();
		}
		
		/**
		 * 转换 BMSPack。
		 */
		protected function convertBMSPack(event:BMSEvent):void
		{
			trace("Main.convertBMSPack(event)");
			
			const bmsPack:BMSPack = event.currentTarget as BMSPack;
			
			bmsPack.removeEventListener(BMSEvent.LOADED, arguments.callee);
			
			// 转换。
			const converter:BMS2OSUConverter = new BMS2OSUConverter(config, bmsPack);
			const beatmap:Beatmap = converter.convert();
			
			b2mChannel.send(HEAD_ARRANGING);
			beatmap.collectResources(); // 此处是同步的，要在卡之前更新一次视图。
			
			
			// 设置输出文件夹。
			const outputDir:File = new File(config.outputDirStr);
			
			// 根据当前正在处理的 bmsPack 索引判断是应该继续处理下一个还是处理完成了。
			const listener:Function = processingBMSPackIndex == bmsPacks.length - 1 ?
				complete : nextBMSPack;
			
			beatmap.addEventListener(BMSEvent.COPYING_OSU, sendBMSProgress);
			beatmap.addEventListener(BMSEvent.COPYING_WAV, sendBMSProgress);
			beatmap.addEventListener(BMSEvent.COPYING_BMP, sendBMSProgress);
			beatmap.addEventListener(Event.COMPLETE, listener);
			beatmap.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
			beatmap.addEventListener(ErrorEvent.ERROR, onError);
			
			// 保存到输出文件夹。
			beatmap.saveAsync(outputDir);
			
			function nextBMSPack(event:Event):void
			{
				beatmap.removeEventListener(Event.COMPLETE, arguments.callee);
				
				processingBMSPackIndex++;
				sendBMSPackProgress(bmsPacks[processingBMSPackIndex - 1].directory.name,
					processingBMSPackIndex, bmsPacks.length);
				
				collectBMSes();
			}
			
			function onIoError(event:IOErrorEvent):void
			{
				trace(event.toString());
			}
			
			function onError(event:ErrorEvent):void
			{
				trace(event.toString());
			}
		}
		
		private function complete(event:Event):void
		{
			const beatmap:Beatmap = event.currentTarget as Beatmap;
			
			beatmap.removeEventListener(Event.COMPLETE, arguments.callee);
			
			processingBMSPackIndex++;
			sendBMSPackProgress(bmsPacks[processingBMSPackIndex - 1].directory.name,
				processingBMSPackIndex, bmsPacks.length);
			
			b2mChannel.send('complete');
			
			trace('Complete: ' + beatmap.name + ' !');
		}
		
		protected function bmsPack_IoErrorHandler(event:IOErrorEvent):void
		{
			trace(event.toString());
		}
		
		/**
		 * 异步遍历目录。文件和文件夹都会调用。
		 * 把它放进来的原因是我的库可能会变，另外重点是这个函数真的能通用？
		 * @param directory 要遍历的目录
		 * @param walkFunc 遍历文件的函数 function(file:File[, dir:File]):void/Boolean（条件返回 true 则不在此 file 中继续遍历）
		 * @param completeFunc 完成遍历后的函数 function():void
		 * @param isRootOnly 是否只遍历根目录
		 */
		public static function walkDirectoryAsync(directory:File, walkFunc:Function,
												  completeFunc:Function,
												  isRootOnly:Boolean = false):void
		{
			
			const walkingDirs:Vector.<File> = new <File>[];
			
			directory.addEventListener(FileListEvent.DIRECTORY_LISTING, directory_listingHandler);
			walkingDirs.push(directory);
			directory.getDirectoryListingAsync();
			
			function directory_listingHandler(event:FileListEvent):void
			{
				const dir:File = event.currentTarget as File;
				dir.removeEventListener(FileListEvent.DIRECTORY_LISTING, arguments.callee);
				walkingDirs.splice(walkingDirs.indexOf(dir), 1);
				
				const files:Array = event.files;
				for each (var file:File in files)
				{
					if (walkFunc(file, dir))
						break;
					
					if (!isRootOnly && file.isDirectory)
					{
						file.addEventListener(FileListEvent.DIRECTORY_LISTING, arguments.callee);
						walkingDirs.push(file);
						file.getDirectoryListingAsync();
					}
				}
				
				if (walkingDirs.length == 0)
					completeFunc();
			}
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  Progress
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		private function sendBMSProgress(event:BMSEvent):void
		{
			b2mChannel.send(HEAD_BMS_PROGRESS);
			b2mChannel.send([event.type, event.res, event.value, event.total]);
		}
		
		private function sendBMSPackProgress(...rest):void
		{
			b2mChannel.send(HEAD_BMSPACK_PROGRESS);
			b2mChannel.send(rest);
		}
	}
}


package workers 
{
	import errors.BMSError;
	import events.BMSEvent;
	import flash.display.Sprite;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.FileListEvent;
	import flash.events.IOErrorEvent;
	import flash.events.UncaughtErrorEvent;
	import flash.filesystem.File;
	import flash.net.registerClassAlias;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import models.Config;
	import songs.bmses.BMS;
	import songs.bmses.BMSPack;
	import songs.osus.Beatmap;
	import songs.osus.BMS2OSUConverter;
	
	/**
	 * BMS 转换流程
	 * 1. 收集各个 BMSPack。
	 * 2. 加载各个 BMSPack。
	 * 3. 其中，收集各个 BMS。
	 * 4. 加载各个 BMS，并关联 wav 和 bmp。
	 * 5. 整理 BMSPack 里关联的 wav 和 bmp。
	 * 6. 转换各个 BMS。
	 * 7. 复制各个 wav 和 bmp。
	 */
	public final class BackgroundWorker extends Sprite
	{
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Class constants
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		/** 主 Worker 发送开始转换消息，开始扫描文件夹，准备转换。 */
		public static const HEAD_START:String = 'start';
		
		/** 主 Worker 里被取消，发送消息过来。 */
		public static const HEAD_CANCEL:String = 'cancel';
		
		/** 主 Worker 发送，忽略错误 */
		public static const HEAD_IGNORE:String = 'ignore';
		
		/** 主 Worker 发送，重试 */
		public static const HEAD_RETRY:String = 'retry';
				
		/** 向主 Worker 发送消息，已经初始化完毕 */
		public static const HEAD_READY:String = 'ready';

		/** 向主 Worker 发送正在扫描文件夹的消息。 */
		public static const HEAD_COLLECTING:String = 'collecting';
		
		/** 向主 Worker 发送正在整理资源的消息。 */
		public static const HEAD_ARRANGING:String = 'arranging';

		/** 向主 Worker 发送消息，没有扫描到 BMS。 */
		public static const HEAD_NOT_FOUND:String = 'not_found';
		
		/** 向主 Worker 发送，转换完毕。 */
		public static const HEAD_COMPLETE:String = 'complete';
		
		/** 向主 Worker 发送，bms 进度改变。 */
		public static const HEAD_BMS_PROGRESS:String = 'bms_progress';
		
		/** 向主 Worker 发送，bmspack 进度改变。 */
		public static const HEAD_BMSPACK_PROGRESS:String = 'bmspack_progress';
		
		/** 向主 Worker 发送，致命错误，退出执行 */
		public static const HEAD_CRITICAL_ERROR:String = 'critical_error';
		
		/** 向主 Worker 发送，处理错误 */
		public static const HEAD_ERROR:String = 'error';
		
		/** 向主 Worker 发送，处理出错事件 */
		public static const HEAD_ERROR_EVENT:String = 'error_event';
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Class variables
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public static var current:BackgroundWorker;
		
		/** 麻痹 AIR 的 Worker 获取到的路径会乱码，只能用 Main 获取再传过来。 */
		public static var APPLICATION_DIRECTORY:File;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Constructor
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function BackgroundWorker()
		{
			current = this;
			init();
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Variables
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		private var m2bChannel:MessageChannel;
		private var b2mChannel:MessageChannel;
		
		private const file:File = new File();
		private const files:Vector.<File> = new <File>[];
		
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
			
			sendReady();
		}
		
		/**
		 * 异步收集所有内含 BMS 的文件夹，一检测到（它里面含有 BMS）就返回，
		 * 创建对应的 BMSPack，最后收集完毕调用 loadAll()。
		 * @see #walkDirectoryAsync()
		 */
		private function collectBMSPacks():void
		{
			trace( "BackgroundWorker.collectBMSPacks" );
			trySend(HEAD_COLLECTING);
			
			bmsPacks = new <BMSPack>[];
			
			try
			{
				const bmsDir:File = new File(config.bmsDirStr);
			}
			catch (error:ArgumentError)
			{
				sendError(error);
				return;
			}
			
			walkDirectoryAsync(bmsDir, walk, error, nextPhase, false);
			
			function walk(file:File, dir:File):Boolean
			{
				//trace("Main.walkFunc(file, dir) : ", file.name);
				if (file.isDirectory == false && BMS.isBMS(file))
				{
					bmsPacks.push(new BMSPack(dir, config));
					return true;
				}
				
				return false;
			}
			
			function error(event:IOErrorEvent):void 
			{
				sendErrorEvent(event);
			}
			
			function nextPhase():void
			{
				if (bmsPacks.length == 0)
				{
					trySend(HEAD_NOT_FOUND);
					return;
				}
				
				processingBMSPackIndex = 0;
				sendBMSPackProgress(bmsPacks[processingBMSPackIndex].directory.name, processingBMSPackIndex, bmsPacks.length);
				
				// 先全部加上事件
				for each (var bmsPack:BMSPack in bmsPacks) 
				{
					bmsPack.addEventListener(BMSEvent.COLLECTING, sendBMSProgress);
					bmsPack.addEventListener(BMSEvent.COLLECTED, loadBMSPack);
					bmsPack.addEventListener(IOErrorEvent.IO_ERROR, bmsPack_IoErrorHandler);
				}
				
				collectBMSes();
			}
		}
		
		/**
		 * 异步操作
		 * 出错为严重错误
		 */
		protected function collectBMSes():void
		{
			const bmsPack:BMSPack = bmsPacks[processingBMSPackIndex];
			
			try 
			{
				bmsPack.collectAll();
			}
			catch (error:Error)
			{
				sendError(new BMSError('在收集过程中发生严重错误', error, bmsPack.directory));
				nextBMSPack();
			}
		}
		
		/**
		 * 异步操作
		 * 等到 bmsPack 收集完毕了，就一个一个开始转换
		 * 出错为严重错误
		 */
		protected function loadBMSPack(event:BMSEvent):void
		{
			const bmsPack:BMSPack = bmsPacks[processingBMSPackIndex];
			
			bmsPack.removeEventListener(BMSEvent.COLLECTING, sendBMSProgress);
			bmsPack.removeEventListener(BMSEvent.COLLECTED, loadBMSPack);
			bmsPack.removeEventListener(IOErrorEvent.IO_ERROR, bmsPack_IoErrorHandler);
			
			bmsPack.addEventListener(BMSEvent.LOADING, sendBMSProgress);
			bmsPack.addEventListener(BMSEvent.LOADED, parseBMSPack);
			
			try 
			{
				bmsPack.loadAll();
			}
			catch (error:Error)
			{
				sendError(new BMSError('在加载过程中发生严重错误', error, bmsPack.directory));
				nextBMSPack();
			}
		}
		
		/**
		 * 同步操作
		 * 这里出错的话真是未知错误，会导致退出执行……
		 * @param	event
		 */
		protected function parseBMSPack(event:BMSEvent):void
		{
			trace("Main.parseBMSPack(event)");
			const bmsPack:BMSPack = event.currentTarget as BMSPack;
			
			bmsPack.removeEventListener(BMSEvent.LOADING, sendBMSProgress);
			bmsPack.removeEventListener(BMSEvent.LOADED, parseBMSPack);
			
			bmsPack.addEventListener(BMSEvent.PARSING, sendBMSProgress);
			bmsPack.addEventListener(BMSEvent.PARSED, convertBMSPack);
			
			try 
			{
				bmsPack.parseAll();
			}
			catch (error:Error)
			{
				sendError(new BMSError('解析全部 BMS 过程中出现了未知错误，不幸地退出。不是我的错，是 Flash 太坑爹！', error, bmsPack.directory));
				nextBMSPack();
			}
		}
		
		/**
		 * 转换 BMSPack。
		 */
		protected function convertBMSPack(event:BMSEvent):void
		{
			const bmsPack:BMSPack = event.currentTarget as BMSPack;
			
			bmsPack.removeEventListener(BMSEvent.PARSING, sendBMSProgress);
			bmsPack.removeEventListener(BMSEvent.PARSED, convertBMSPack);
			
			// 转换。
			const converter:BMS2OSUConverter = new BMS2OSUConverter(config, bmsPack);
			try 
			{
				const beatmap:Beatmap = converter.convert();
			}
			catch (error:Error)
			{
				sendError(new BMSError('转换' + beatmap.name + '时出现致命错误，呜呜', error, bmsPack.directory));
				next();
				return;
			}
			
			trySend(HEAD_ARRANGING);
			try 
			{
				beatmap.collectResources(); // 此处是同步的，要在卡之前更新一次视图。
			}
			catch (error:Error)
			{
				sendError(new BMSError('在' + beatmap.name + '收集资源时出现致命错误', error, bmsPack.directory));
				next();
				return;
			}
			
			
			// 设置输出文件夹。
			try 
			{
				const outputDir:File = new File(config.outputDirStr);
			}
			catch (error:ArgumentError)
			{
				sendError(error);
				next();
				return;
			}
			
			// 根据当前正在处理的 bmsPack 索引判断是应该继续处理下一个还是处理完成了。
			const listener:Function = processingBMSPackIndex == bmsPacks.length - 1 ? complete : next;
			
			beatmap.addEventListener(BMSEvent.COPYING_OSU, sendBMSProgress);
			beatmap.addEventListener(BMSEvent.COPYING_WAV, sendBMSProgress);
			beatmap.addEventListener(BMSEvent.COPYING_BMP, sendBMSProgress);
			beatmap.addEventListener(Event.COMPLETE, listener);
			beatmap.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
			beatmap.addEventListener(ErrorEvent.ERROR, onError);
			
			// 保存到输出文件夹。
			try 
			{
				beatmap.saveAsync(outputDir);
			} 
			catch (error:Error) 
			{
				sendError(new BMSError('在保存' + beatmap.name + '时出现致命错误', error, bmsPack.directory));
				next();
				return;
			}
			
			function next(event:Event = null):void
			{
				removeEventListeners();
				
				nextBMSPack();
			}
			
			function complete(event:Event):void
			{
				removeEventListeners();
				
				processingBMSPackIndex++;
				sendBMSPackProgress(bmsPacks[processingBMSPackIndex - 1].directory.name, processingBMSPackIndex, bmsPacks.length);
				
				trySend('complete');
				
				trace('Complete: ' + beatmap.name + ' !');
			}
			
			function onIoError(event:IOErrorEvent):void
			{
				sendErrorEvent(event);
			}
			
			function onError(event:ErrorEvent):void
			{
				sendErrorEvent(event);
			}
			
			function removeEventListeners():void 
			{
				beatmap.removeEventListener(BMSEvent.COPYING_OSU, sendBMSProgress);
				beatmap.removeEventListener(BMSEvent.COPYING_WAV, sendBMSProgress);
				beatmap.removeEventListener(BMSEvent.COPYING_BMP, sendBMSProgress);
				beatmap.removeEventListener(Event.COMPLETE, complete);
				beatmap.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);
				beatmap.removeEventListener(ErrorEvent.ERROR, onError);
			}
		}
		
		
		public function nextBMSPack():void
		{
			processingBMSPackIndex++;
			sendBMSPackProgress(bmsPacks[processingBMSPackIndex - 1].directory.name, processingBMSPackIndex, bmsPacks.length);
			
			collectBMSes()
		}
		
		protected function bmsPack_IoErrorHandler(event:IOErrorEvent):void
		{
			sendErrorEvent(event);
		}
		
		/**
		 * 异步遍历目录。文件和文件夹都会调用。
		 * 把它放进来的原因是我的库可能会变，另外重点是这个函数真的能通用？
		 * @param directory 要遍历的目录
		 * @param walkFunc 遍历文件的函数 function(file:File[, dir:File]):void/Boolean（条件返回 true 则不在此 file 中继续遍历）
		 * @param errorFunc 出错的函数 function(event:ErrorEvent):void
		 * @param completeFunc 完成遍历后的函数 function():void
		 * @param isRootOnly 是否只遍历根目录
		 */
		public static function walkDirectoryAsync(directory:File,
												  walkFunc:Function,
												  errorFunc:Function,
												  completeFunc:Function,
												  isRootOnly:Boolean = false):void
		{
			
			const walkingDirs:Vector.<File> = new <File>[];
			
			directory.addEventListener(FileListEvent.DIRECTORY_LISTING, directory_listingHandler);
			directory.addEventListener(IOErrorEvent.IO_ERROR, errorFuncWrapper);
			walkingDirs.push(directory);
			directory.getDirectoryListingAsync();
			
			function directory_listingHandler(event:FileListEvent):void
			{
				const dir:File = event.currentTarget as File;
				dir.removeEventListener(FileListEvent.DIRECTORY_LISTING, directory_listingHandler);
				dir.removeEventListener(IOErrorEvent.IO_ERROR, errorFuncWrapper);
				walkingDirs.splice(walkingDirs.indexOf(dir), 1);
				
				const files:Array = event.files;
				for each (var file:File in files)
				{
					if (walkFunc(file, dir))
						break;
					
					if (!isRootOnly && file.isDirectory)
					{
						file.addEventListener(FileListEvent.DIRECTORY_LISTING, directory_listingHandler);
						file.addEventListener(IOErrorEvent.IO_ERROR, errorFuncWrapper);
						
						walkingDirs.push(file);
						file.getDirectoryListingAsync();
					}
				}
				
				if (walkingDirs.length == 0)
					completeFunc();
			}
			
			// 为了确实地删除所有侦听器
			function errorFuncWrapper(event:IOErrorEvent):void 
			{
				const dir:File = event.currentTarget as File;
				dir.removeEventListener(FileListEvent.DIRECTORY_LISTING, directory_listingHandler);
				dir.removeEventListener(IOErrorEvent.IO_ERROR, errorFunc);

				errorFunc(event);
			}
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  Send
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		private function trySend(arg:*, queueLimit:int = -1):void 
		{
			try 
			{
				b2mChannel.send(arg);
			}
			catch (error:Error)
			{
				sendError(error);
			}
		}
		
		private function sendReady():void 
		{
			trySend(HEAD_READY);
		}
		
		private function sendBMSProgress(event:BMSEvent):void
		{
			trySend(HEAD_BMS_PROGRESS);
			trySend([event.type, event.res, event.value, event.total]);
		}
		
		private function sendBMSPackProgress(...rest):void
		{
			trySend(HEAD_BMSPACK_PROGRESS);
			trySend(rest);
		}
		
		registerClassAlias('Error', Error);
		registerClassAlias('errors.BMSError', BMSError);
		public function sendError(error:Error):void 
		{
			trace( "BackgroundWorker.sendError > error : " + error );
			if (error is BMSError) 
			{
				const bmsError:BMSError = error as BMSError;
				trySend(HEAD_ERROR);
				trySend({message: error.message, stackTrace: error.getStackTrace(), file: bmsError.file});
			}
			else 
			{
				trySend(HEAD_CRITICAL_ERROR);
				trySend({message: error.message, stackTrace: error.getStackTrace()});
			}
			
		}
		
		registerClassAlias('Event', Event);
		public function sendErrorEvent(event:Event):void 
		{
			trace( "BackgroundWorker.sendError > event : " + event );
			trySend(HEAD_ERROR_EVENT);
			trySend(event);
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  Receive
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function start():void 
		{
			config = m2bChannel.receive(true);
			
			try 
			{
				collectBMSPacks();
			}
			catch (error:Error)
			{
				sendError(error);
			}
		}
		
		public function cancel():void 
		{
			Worker.current.terminate();
		}
		
		public function retry():void 
		{
			
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Event Handlers
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		registerClassAlias('models.Config', Config);
		private function onM2BChannelMessage(event:Event):void
		{
			if (!m2bChannel.messageAvailable) return;
			
			const msg:String = m2bChannel.receive(true) as String;
			if (msg in this) 
			{
				this[msg]();
			}
			else
			{
				throw new Error('未知的信息：' + msg);
			}
		}
		
		private function onUncaughtError(event:UncaughtErrorEvent):void 
		{
			sendErrorEvent(event);
			event.preventDefault();
		}
	}
}


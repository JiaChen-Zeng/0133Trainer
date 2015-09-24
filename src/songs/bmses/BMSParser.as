package songs.bmses
{
	import errors.BMSError;
	import errors.BMSError;
	import flash.filesystem.File;
	import moe.aoi.utils.Chain;
	import songs.osus.BMS2OSUConverter;
	import workers.BackgroundWorker;

	public class BMSParser
	{
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Class constants
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		private static const RE_HEADER:RegExp = /^#((?!(?:WAV|BMP|BPM|STOP)(?:\w{2}))\w+)[ \t]+(.*)$/i;
		
		private static const RE_ID:RegExp = /^#(WAV|BMP|BPM|STOP)(\w{2})\s+(.+)$/i;
		
		private static const RE_MAIN_DATA:RegExp = /^#(\d{3})(\d{2}):([\w.]+)$/i;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Constructor
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function BMSParser(bms:BMS)
		{
			this.bms = bms;
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Variables
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		private var bms:BMS;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Methods
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		internal function parse():void
		{
			bms.init();
			
			//var chain:Chain = new Chain(Vector.<*>(bms.lines));
			//chain.func = parseLine;
			//chain.fail = BackgroundWorker.current.sendWarn;
			//chain.done = sortMainData;
			//chain.start();
			
			for each (var line:String in bms.lines) 
			{
				parseLine(line);
			}
			
			sortMainData();
		}
		
		private function parseLine(line:String):void
		{
			if (RE_HEADER.test(line))
			{
				parseHeader.apply(null, RE_HEADER.exec(line).slice(1));
			}
			else if (RE_ID.test(line))
			{
				parseId.apply(null, RE_ID.exec(line).slice(1));
			}
			else if (RE_MAIN_DATA.test(line))
			{
				parseMainData.apply(null, RE_MAIN_DATA.exec(line).slice(1));
			}
			// 空行……什么的，就算了
		}
		
		private function parseHeader(key:String, value:String):void
		{
			try
			{
				// 按属性的类型来赋值。
				const attr:String = key.toLowerCase();
				
				if (attr == 'difficalty') // 辣鸡谱师连英文都会拼错，是在下输了！
				{
					bms.difficulty = parseInt(value);
					trace('this[' + key.toLowerCase()+ '] = ' + value + ';');
					return;
				}
				else if (attr == 'inobj')
				{
					bms.lnobj = value;
					trace('this[' + key.toLowerCase()+ '] = ' + value + ';');
					return;
				}
				
//				trace(typeof bms[attr]);
				
				if (bms[attr] is uint || bms[attr] is int)
				{
					bms[attr] = parseInt(value);
				}
				else if (bms[attr] is Number)
				{
					bms[attr] = parseFloat(value);
				}
				else
				{
					if (attr == 'stagefile' ||  attr == 'banner' ||  attr == 'backbmp')
					{
						bms[attr] = fixBmp(value);
					}
					else
					{
						bms[attr] = value;
					}
				}
			} 
			catch(error:Error) 
			{
				// TODO: 忽略|取消。
				// 模糊匹配写错了的属性。
				BackgroundWorker.current.sendError(new BMSError(BMSError.HEADER_WARN + '未知的属性 ' + attr, error, bms.file));
			}
			
			trace('this[' + key.toLowerCase()+ '] = ' + value + ';');
		}
		
		private function parseId(type:String, key:String, value:String):void
		{
			if (type == BMS.TYPE_WAV)
			{
				value = fixWav(value);
			}
			else if (type == BMS.TYPE_BMP)
			{
				value = fixBmp(value);
			}
				
			bms[type.toLowerCase() + 's'][parseInt(key, 36)] = value;
		}
		
		private function parseMainData(measureIndexStr:String, channelStr:String, content:String):void
		{
			const measureIndex:uint = parseInt(measureIndexStr);
			const channel:uint = parseInt(channelStr);
			var data:Data;
			
			// 节拍通道直接是小数。
			if (channel == BMS.CHANNEL_METER)
			{
				data = new Data();
				data.measureIndex = measureIndex;
				data.channel = channel;
				data.content = parseFloat(content);
				// 防止排序出问题。
				data.index = 0;
				data.length = 1;
				addData(data);
				return;
			}
			
			// 匹配两个两个的字符。
			var contentArr:Array = content.match(/\w{2}/g);
			var contentArr_length:uint = contentArr.length;
			for (var i:int = 0; i < contentArr_length; i++) 
			{
				var contentStr:String = contentArr[i];
				if (contentStr == '00') continue; // 没有数据
				
				data = new Data();
				data.measureIndex = measureIndex;
				data.channel = channel;
				
				if (channel == BMS.CHANNEL_BPM) // BPM 通道是16进制
				{
					data.content = parseInt(contentStr, 16);
				}
				else
				{
					data.content = parseInt(contentStr, 36);
				}
				
				data.index = i;
				data.length = contentArr_length;
				
				addData(data);
			}
		}
		
		private function addData(data:Data):void
		{
			const measures:Array = bms.measures;
			const measureIndex:uint = data.measureIndex;
			
			if (!(measureIndex in measures))
			{
				measures[measureIndex] = new <Data>[];
			}
			
			measures[measureIndex].push(data);
		}
		
		/**
		 * 使数据按照通道从小到大排列，另外 stop 通道放到最后。
		 * @see BMS#CHANNEL_STOP
		 */
		private function sortMainData():void
		{
			// 选取每个小节。
			for each (var measure:Vector.<Data> in bms.measures) 
			{
				var measure_length:uint = measure.length;
				// 选取小节内的每2个数据，冒泡排序。
				for (var i:int = 0; i < measure_length; i++) 
				{
					for (var j:int = i + 1; j < measure_length; j++) 
					{
						var data1:Data = measure[i];
						var data2:Data = measure[j];
						
						var time1:Number = data1.index / data1.length;
						var time2:Number = data2.index / data2.length;
						
						// 满足条件就交换顺序。
						if (time1 > time2) // 按从时间小到大排列。
						{
							measure[i] = data2;
							measure[j] = data1;
						}
						else if (time1 === time2) // 时间相同，按通道排序，另外 stop 排最后！
						{
							if (data1.channel == BMS.CHANNEL_STOP) // 第一个是 stop，放后面。
							{
								// 往后排（交换）。
								measure[i] = data2;
								measure[j] = data1;
							}
							else if (data2.channel == BMS.CHANNEL_STOP) // 第二个是 stop，已经没错，不用排。
							{
								// 无动作。
							}
							else if (data1.channel > data2.channel) // 都不是 stop，按通道排序。
							{
								measure[i] = data2;
								measure[j] = data1;
							}
						}
					}
				}
			}
		}
		
		/**
		 * 艹，怎么会BMS文件里的WAV文件后缀名是wav，实际上是ogg啊，搞不明白了。
		 * 日，bmp是png。
		 */
		private function fixWav(fileName:String):String
		{
			const originalFileName:String = fileName;
			const dir:File = bms.bmsPack.directory;
			
			var file:File = dir.resolvePath(BMS2OSUConverter.matchPath(fileName));
			if (file.exists) return fileName;
			
			const re:RegExp = /\.(\w+)$/i;
			fileName = fileName.replace(re, '.ogg');
			file = dir.resolvePath(BMS2OSUConverter.matchPath(fileName));
			
			if (file.exists) return fileName;
			
			fileName = fileName.replace(re, '.wav');
			file = dir.resolvePath(BMS2OSUConverter.matchPath(fileName));
			
			if (file.exists) return fileName;
			else
			{
				//trace(BMSError.RESOURCE_WARN + originalFileName);
				BackgroundWorker.current.sendError(new BMSError(BMSError.RESOURCE_WARN + originalFileName, null, bms.file));
			}
			
			return fileName;
		}
		
		private function fixBmp(fileName:String):String
		{
			const originalFileName:String = fileName;
			const dir:File = bms.bmsPack.directory;
			
			var file:File = dir.resolvePath(BMS2OSUConverter.matchPath(fileName));
			if (file.exists) return fileName;
			
			const re:RegExp = /\.(\w+)$/i;
			
			// 全部都j8试一遍。
			// 图片：
			fileName = fileName.replace(re, '.png');
			file = dir.resolvePath(BMS2OSUConverter.matchPath(fileName));
			
			if (file.exists) return fileName;
			
			fileName = fileName.replace(re, '.jpg');
			file = dir.resolvePath(BMS2OSUConverter.matchPath(fileName));
			
			if (file.exists) return fileName;
			
			fileName = fileName.replace(re, '.jpeg');
			file = dir.resolvePath(BMS2OSUConverter.matchPath(fileName));
			
			if (file.exists) return fileName;
			
			fileName = fileName.replace(re, '.bmp');
			file = dir.resolvePath(BMS2OSUConverter.matchPath(fileName));
			
			if (file.exists) return fileName;
			
			// 视频：
			fileName = fileName.replace(re, '.mpg');
			file = dir.resolvePath(BMS2OSUConverter.matchPath(fileName));
			
			if (file.exists) return fileName;
			
			fileName = fileName.replace(re, '.mpeg');
			file = dir.resolvePath(BMS2OSUConverter.matchPath(fileName));
			
			if (file.exists) return fileName;
			
			fileName = fileName.replace(re, '.avi');
			file = dir.resolvePath(BMS2OSUConverter.matchPath(fileName));
			
			if (file.exists) return fileName;
			else
			{
				BackgroundWorker.current.sendError(new BMSError(BMSError.RESOURCE_WARN + originalFileName, null, bms.file));
			}
			
			return fileName;
		}
	}
}


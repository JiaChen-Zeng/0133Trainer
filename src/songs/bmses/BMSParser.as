package songs.bmses
{
	import flash.filesystem.File;
	
	import songs.osus.BMS2OSUConverter;

	public class BMSParser
	{
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Class constants
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		/**
		 * 映射出 channel 的排列顺序，以便转换。
		 * 只包含几个比较重要的，对 offset 有影响的 channel，其他的就按 channel 的值来排序吧。
		 **/
		private static const CHANNEL_ORDER_MAP:Object =
		{ // 日狗，做了半天发觉没错就是按通道直接解析下来的顺序！
			9: 0, // BMS.CHANNEL_STOP
			2: 1, // BMS.CHANNEL_METER
			3: 2, // BMS.CHANNEL_BPM
			8: 3 // BMS.CHANNEL_BPM_EXTENDED
		};
		
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
		
		internal function load():void
		{
			bms.init();
			
			for each (var line:String in bms.lines) 
			{
				parseLine(line);
			}
			
			sortMainData();
		}
		
		private function parseLine(line:String):void
		{
			if (RE_HEADER.test(line))
				parseHeader.apply(null, RE_HEADER.exec(line).slice(1));
			else if (RE_ID.test(line))
				parseId.apply(null, RE_ID.exec(line).slice(1));
			else if (RE_MAIN_DATA.test(line))
				parseMainData.apply(null, RE_MAIN_DATA.exec(line).slice(1));
		}
		
		private function parseHeader(key:String, value:String):void
		{
			try
			{
				// 按属性的类型来赋值。
				const attr:String = key.toLowerCase();
				
				if (attr == 'difficalty') // 辣鸡谱师连英文都会拼错，葵真是服了！
				{
					bms.difficulty = parseInt(value);
					trace('this[' + key.toLowerCase()+ '] = ' + value + ';');
					return;
				}
				
//				trace(typeof bms[attr]);
				
				if (bms[attr] is uint
					||  bms[attr] is int)
					bms[attr] = parseInt(value);
				else if (bms[attr] is Number)
					bms[attr] = parseFloat(value);
				else
				{
					if (attr == 'stagefile'
					||  attr == 'banner'
					||  attr == 'backbmp')
						bms[attr] = fixBmp(value);
					else
						bms[attr] = value;
				}
			} 
			catch(error:Error) 
			{
				// TODO: 忽略|取消。
				throw error;
			}
			
			trace('this[' + key.toLowerCase()+ '] = ' + value + ';');
		}
		
		private function parseId(type:String, key:String, value:String):void
		{
			if (type === BMS.TYPE_WAV)
				value = fixWav(value);
			else if (type === BMS.TYPE_BMP)
				value = fixBmp(value);
				
			bms[type.toLowerCase() + 's'][parseInt(key, 36)] = value;
		}
		
		private function parseMainData(measureIndexStr:String, channelStr:String, content:String):void
		{
			const measureIndex:uint = parseInt(measureIndexStr);
			const channel:uint = parseInt(channelStr);
			var data:Data;
			
			// 节拍通道直接是小数。
			if (channel === BMS.CHANNEL_METER)
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
				if (contentStr === '00') // 没有数据。
					continue;
				
				data = new Data();
				data.measureIndex = measureIndex;
				data.channel = channel;
				
				if (channel == BMS.CHANNEL_BPM
				||  channel == BMS.CHANNEL_STOP) // BPM 和 STOP 通道是16进制。
					data.content = parseInt(contentStr, 16);
				else
					data.content = parseInt(contentStr, 36);
				
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
		 * 重构，解除顺序问题对 data 的影响？
		 * converter.convertMainData()？ 里也来按照特定的通道顺序来转换，避免冲突和复杂的逻辑判断。
		 * 可能得事先排好顺序。
		 * PS：写这段话的时候葵并没有看相关代码，全凭细微的记忆和爆发的脑洞，不负任何责任。
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
						else if (time1 === time2) // 时间相同，按通道排序。
						{
							var in1:Boolean = data1.channel in CHANNEL_ORDER_MAP;
							var in2:Boolean = data2.channel in CHANNEL_ORDER_MAP;
							
							if (!in1 && !in2) // 不需要特定排序，按通道从小到大排列。
							{
								if (data1.channel > data2.channel)
								{
									measure[i] = data2;
									measure[j] = data1;
								}
							}
							else if (!in1 && in2) // 前面的不需特定排序，后面需，交换。
							{
								measure[i] = data2;
								measure[j] = data1;
							}
							else if (in1 && !in2) // 前面的需特定排序，后面不需，不交换。
							{
								
							}
							else // 都需特定排序，按照特定排序排列。
							{
								if (CHANNEL_ORDER_MAP[data1.channel] > CHANNEL_ORDER_MAP[data2.channel])
								{
									trace('特定排序');
									measure[i] = data2;
									measure[j] = data1;
								}
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
			const re:RegExp = /\.(\w+)$/;
			const dir:File = bms.bmsPack.directory;
			
			var file:File = dir.resolvePath(BMS2OSUConverter.matchPath(fileName));
			if (file.exists)
				return fileName;
			
			fileName = fileName.replace(re, '.ogg');
			file = dir.resolvePath(BMS2OSUConverter.matchPath(fileName));
			if (file.exists)
				return fileName;
			else
			{
				// TODO: 提示。
				trace('捉鸡');
			}
			
			return fileName;
		}
		
		private function fixBmp(fileName:String):String
		{
			const re:RegExp = /\.(\w+)$/;
			const dir:File = bms.bmsPack.directory;
			
			var file:File = dir.resolvePath(BMS2OSUConverter.matchPath(fileName));
			if (file.exists)
				return fileName;
			
			fileName = fileName.replace(re, '.png');
			file = dir.resolvePath(BMS2OSUConverter.matchPath(fileName));
			if (file.exists)
				return fileName;
			
			fileName = fileName.replace(re, '.jpg');
			file = dir.resolvePath(BMS2OSUConverter.matchPath(fileName));
			
			if (file.exists)
				return fileName;
			
			fileName = fileName.replace(re, '.mpg');
			file = dir.resolvePath(BMS2OSUConverter.matchPath(fileName));
			
			if (file.exists)
			{
				return fileName;
			}
			else
			{
				// TODO: 提示。
				trace('捉鸡');
			}
			
			return fileName;
		}
	}
}


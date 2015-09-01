package songs.osus
{
	import mx.utils.StringUtil;
	
	import models.Config;
	
	import songs.bmses.BMS;
	import songs.bmses.BMSPack;
	import songs.bmses.Data;
	import songs.bmses.IBMS;
	
	public final class BMS2OSUConverter
	{
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Class constants
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆ ☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		private static const LANE_MAP_BMS:Object =
		{
			16: 0,
			11: 1,
			12: 2,
			13: 3,
			14: 4,
			15: 5,
			18: 6,
			19: 7,
			
			26: 0,
			21: 1,
			22: 2,
			23: 3,
			24: 4,
			25: 5,
			28: 6,
			29: 7,
			
			56: 0,
			51: 1,
			52: 2,
			53: 3,
			54: 4,
			55: 5,
			58: 6,
			59: 7,
			
			66: 0,
			61: 1,
			62: 2,
			63: 3,
			64: 4,
			65: 5,
			68: 6,
			69: 7
		};
		
		private static const LANE_MAP_PMS:Object =
		{
			11: 0,
			12: 1,
			13: 2,
			14: 3,
			15: 4,
			22: 5,
			23: 6,
			24: 7,
			25: 8,
			
			51: 0,
			52: 1,
			53: 2,
			54: 3,
			55: 4,
			62: 5,
			63: 6,
			64: 7,
			65: 8
		};
		
		public static var PREFIX_SOUND_FILE:String = 'wav/';
		
		public static var PREFIX_BMP_FILE:String = 'bmp/';
		
		private static const MINUTE:uint = 60000;
		
		private static const MAX_DIVISION:uint = 192;
		
		/** 从 Sakuzyo - Altale (__M A S__) [7K MX] 里找到的 time 数值，感谢神麻婆 mas！ **/
		private static const STOP_TIME:Number = 999999999.666667;
		
		private static const RE_VIDEO:RegExp = /\.(avi|mpg|mpeg)$/i;
		
		public static const FORMAT_CONVERT:String = '.mp4';
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Class methods
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public static function matchPath(path:String):String
		{
			path = path.replace('\\', '/');
			if (path.charAt() === '/')
				path.substring(1);
			
			return path;
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Constructor
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function BMS2OSUConverter(config:Config, iBMS:IBMS)
		{
			this.config = config;
			this.iBMS = iBMS;
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Variables
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		private var config:Config;
		
		private var bms:BMS;
		
		private var iBMS:IBMS;
		
		private var osu:OSU;
		
		private var beatmap:Beatmap;
		
		private var keyCounter:Array;
		
		private var haveKeySound:Boolean;
		
		private var haveScratch:Boolean;
		
		/**
		 * 包括 BPM、BPM_EXTENDED。
		 */
		private var lastBPMData:Data;
		
		/**
		 * 只指 BPM。
		 */
		private var lastBPM3Data:Data;
		
		/**
		 * 节拍只会作用于本小节，不会持续到下一小节。
		 */
		private var thisMeterData:Data;
		
		private var thisMeterEndTimingPoint:TimingPoint;
		
		private var thisMeterTimingPoint:TimingPoint;
		
		private var nextMeterData:Data;
		
		private var lastTimingPoint:TimingPoint;
		
		/**
		 * 必须用 Number，这个是原始的 offset 数值，没有 Math.round() 过的。
		 * 解决小数被舍去的问题。
		 */
		private var lastTimingPoint_offset:Number;
		
		/**
		 * 记录最后的 tp 位置，类似于 measureIndex + index / length。
		 * 因为 meter 终止处没 data，取不到。
		 */
		private var lastTimingPoint_position:Number;
		
		/**
		 * 解决 getUnknownTime() 里参照的最后一个 bpm3data 不对的问题。
		 */
		private var lastRedTimingPoint_bpm:Number;
		
		/**
		 * 必须用 Number，这个是原始的 offset 数值，没有 Math.round() 过的。
		 * 为了调整有 stop 的 meter 小节的 offset，需要精确的数值。
		 */
		private var thisMeterEndTimingPoint_offset:Number;
		
		/**
		 * 为了正确计算有节拍的，并且其中还有变速的小节的 offset，需要记录位置。
		 */
		private var thisMeterEndTimingPoint_position:Number;
		
		/**
		 * 第一个索引是表示玩家，第二个索引是轨道。
		 */
		private var holdingLns:Array = [ [], [] ];
		
		/**
		 * 为了转换长音标模式的 ln。
		 */
		private var lastNotes:Array = [ [], [] ];
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Methods
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  Converts
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function convert(specialStyle:uint = 1):Beatmap
		{
			beatmap = new Beatmap();
			
			// TODO: 不要在这里做 if 判断，直接在 .convertBMS() 接收 iBMS，在内部判断。
			if (iBMS is BMS)
			{
				trace('iBMS is BMS');
				convertBMS(iBMS as BMS);
				beatmap.addOSU(osu);
			}
			else if (iBMS is BMSPack)
			{
				trace('iBMS is BMSPack');
				const bmsPack:BMSPack = iBMS as BMSPack;
				for each (var bms:BMS in bmsPack.bmses) 
				{
					convertBMS(bms)
					beatmap.addOSU(osu);
				}
				
				beatmap.name = bmsPack.directory.name;
				beatmap.bmsPack = bmsPack;
			}
			
			return beatmap;
		}
		
		/**
		 * 一次处理一个。
		 */
		private function convertBMS(bms:BMS):void
		{
			trace("BMS2OSUConverter.convertBMS(bms): ", bms.title);
			this.bms = bms;
			trace("bms.lntype = ", bms.lntype);
			trace("bms.lnobj = ", bms.lnobj);
			osu = new OSU(bms);
			
			convertHeader();
			convertMainData();
		}
		
		private function convertHeader():void
		{
			var res:Object = matchTitle();
			osu.title = osu.titleUnicode = res.title;
			osu.artist = osu.artistUnicode = bms.subartist ?
				bms.artist + ' & ' + bms.subartist :
				bms.artist;
			osu.version = 'Lv. ' + bms.playlevel.toString() || '?';
			// TODO: 单个 bms 的 bmspack 的 version 还是要再做下。
			if (res.version)
				osu.version += ' ' + res.version;
			// TODO: 根据 rank total 设置 HP 和 OD。
			osu.od = config.OD;
			osu.hp = config.HP;
			// TODO: 如果没有 stageFile 的话就取第一个出现的 04 通道的 BMP。话说 BMS 的图片都这么小……？
			if (bms.stagefile)
				osu.background = PREFIX_BMP_FILE + bms.stagefile;
			else if (bms.backbmp)
				osu.background = PREFIX_BMP_FILE + bms.backbmp;
			// TODO: 取第一次设置的的节拍？
//			meter = 
			// 我靠会重名。
//			osu.name = StringUtil.substitute('{0} - {1} ({2}) [{3}]',
//				osu.artist || 'Unkown', osu.title || '', osu.creator, osu.version);
			osu.name = bms.name + '.' + bms.extension;
			osu.tags = 'bms conversion ' + bms.genre;
		}
		
		private function matchTitle():Object
		{
			const bmsPack:BMSPack = bms.bmsPack;
			const obj:Object = {};
			
			if (bmsPack)
			{
				// 在 BMS 包里面的话，难度名就只要去掉歌名 BMS 剩下的就是难度名。
				if (bmsPack.name)
				{
					// 不是混合曲包。
					obj.version = StringUtil.trim(bms.title.replace(bmsPack.name, ''));
					obj.title = bmsPack.name;
				}
				else
				{
					obj.version = '';
					obj.title = bms.title;
				}
			}
			else
			{
				// 是单个的 BMS，那么只能把难度名匹配出来，然后歌名跟上面难度名一样做法。
				obj.version = BMSPack.RE_VERSION.exec(bms.title);
				obj.title = StringUtil.trim(bms.title.replace(obj.verion, ''));
			}
			
			return obj;
		}
		
		// TODO: 要不要把 osu 的 note 从左到右的顺序排列下？效率损失不大的话就干了！
		private function convertMainData():void
		{
			// 计算键数。
			keyCounter = [];
			holdingLns = [];
			
			addFirstTimingPointRedDataIfEmpty();
			
			for each (var measure:Vector.<Data> in bms.measures) 
			{
				for each (var data:Data in measure) 
				{
					// 啊我知道了，因为 note 通道一定在那些控制音乐的通道的后面，所以 note 都会最后转，那就没问题了。
					// 直接转就行，顺序是已经排过了的！
					// No！节拍在 BGM 之后！
					// 貌似没问题，只要在 BPM 之前就 OK。
					convertData(data);
				}
			}
			
			// 知道了键数，再次调用计算出 x 坐标。
			setKeyCount();
			delayOperations();
			
			keyCounter							= null;
			haveKeySound						= false;
			holdingLns							= null;
			lastBPMData							= null;
			lastBPM3Data						= null;
			lastTimingPoint						= null;
			lastTimingPoint_offset				= NaN;
			lastTimingPoint_position			= NaN;
			thisMeterData						= null;
			thisMeterTimingPoint				= null;
			thisMeterEndTimingPoint				= null;
			thisMeterEndTimingPoint_offset		= NaN;
			thisMeterEndTimingPoint_position	= NaN;
		}
		
//		private function getBPMDatas(measure:Vector.<Data>):Vector.<Data>
//		{
//			var bpmDatas:Vector.<Data> = new <Data>[];
//			
//			var measure_length:uint = measure.length;
//			for (var i:int = 0; i < measure_length; i++) 
//			{
//				var data:Data = measure[i];
//				if (data.channel === BMS.CHANNEL_BPM
//				||  data.channel === BMS.CHANNEL_BPM_EXTENDED)
//					bpmDatas.push(data);
//			}
//			
//			return bpmDatas;
//		}
		
		private function convertData(data:Data):void
		{
			setMeterData(data);
			
			switch (data.channel)
			{
				case BMS.CHANNEL_BGM: // 背景音/BGM（WAV）
					convertBGM(data);
					break;
				
				case BMS.CHANNEL_METER: // 节拍
					// OSU 现在不支持变节拍。
					// 竟然有谱用变节拍做变速？
					convertMeter(data);
					break;
				
				case BMS.CHANNEL_BPM: // BPM
					convertBPM(data);
					break;
				
				case BMS.CHANNEL_BGA: // 背景动画/BGA（BMP）
					convertBGA(data);
					break;
				
				case BMS.CHANNEL_MISS: // 弹奏中Miss时出现的画面（BMP）
					// TODO: SB Fail 事件。
					break;
				
				case BMS.CHANNEL_LAYER: // Layer（BMP）
					// 未知。
					break;
				
				case BMS.CHANNEL_BPM_EXTENDED: // Extended BPM
					convertBPM(data);
					break;
				
				case BMS.CHANNEL_STOP: // 暂停
					convertStop(data);
					// TODO: 
					break;
				
				// 11 - 17：1P的弹奏通道（WAV）
				case 11: // 1号键
				case 12: // 2号键
				case 13: // 3号键
				case 14: // 4号键
				case 15: // 5号键
				case 18: // 6号键
				case 19: // 7号键
				case 16: // 转盘
					
				// 21 - 27：2P的弹奏通道（WAV）
				case 21: // 1号键
				case 22: // 2号键
				case 23: // 3号键
				case 24: // 4号键
				case 25: // 5号键
				case 28: // 6号键
				case 29: // 7号键
				case 26: // 转盘
					convertNote(data);
					break;
				
				// 51 - 57：1P的长音通道（WAV）
				case 51: // 1号键
				case 52: // 2号键
				case 53: // 3号键
				case 54: // 4号键
				case 55: // 5号键
				case 58: // 6号键
				case 59: // 7号键
				case 56: // 转盘
					
				// 61 - 67：2P的长音通道（WAV）
				case 61: // 1号键
				case 62: // 2号键
				case 63: // 3号键
				case 64: // 4号键
				case 65: // 5号键
				case 68: // 6号键
				case 69: // 7号键
				case 66: // 转盘
					convertLongNote(data);
					break;
				
				default:
//					throw new Error('未处理的通道：' + data.channel);
			}
		}
		
		/**
		 * 这个函数貌似是为了绑定（设置）此小节的 meterData。
		 */
		private function setMeterData(data:Data):void
		{
			// 加上终止 TP。
			if (thisMeterData
			&&  thisMeterData.measureIndex < data.measureIndex
			&&  data.index > 0) // 第0号物件还是参考上一个小节的 meter。
//			&&  data.channel > 2)
			{	// 看来根本没有进来这里。2015年6月15日23:00:46
				// 可能第0号物件如果是 bpm？ 的话还是要让他进这里（看 if 第三行），然后判断要不要放终止 tp。
				// 然而只是葵的想象而已，具体流程还没看啊。
				// 四暗刻为何 60 小节会进来？
				trace('进入判断要不要放终止 tp');
				trace('现在是第', thisMeterData.measureIndex, '小节');
				// 判断如果要放 meter 的终止 tp 的地方有 bpm 的话就不用放终止 tp 了。
				if (!(lastBPMData.measureIndex === thisMeterData.measureIndex + 1
				&&    lastBPMData.index === 0))
				{
					trace('第', thisMeterData.measureIndex, '小节需要放终止 tp');
					// 没有 bpm，放。
					// 此处为了正确计算 offset，修改了。
					if (uint(thisMeterEndTimingPoint_position) == thisMeterEndTimingPoint_position) // 一样，说明其中没有 bpm，
					{
						// 直接算整个小节。
						thisMeterEndTimingPoint_offset = thisMeterEndTimingPoint_offset +
							getMeasureTime(lastBPMData, thisMeterData)
					}
					else // 其中还有 bpm，
					{
						// 再附加最后一段。
						thisMeterEndTimingPoint_offset = thisMeterEndTimingPoint_offset +
							getMeasureTime(lastBPMData, thisMeterData) *
							(Math.ceil(thisMeterEndTimingPoint_position) - thisMeterEndTimingPoint_position);
					}
					
					thisMeterEndTimingPoint.offset = Math.round(thisMeterEndTimingPoint_offset);
					
					osu.timingPoints.push(thisMeterEndTimingPoint);
					lastTimingPoint = thisMeterEndTimingPoint;
					lastTimingPoint_offset = thisMeterEndTimingPoint_offset; // 原来这里赋给了 round 后的整数，错了！
					lastTimingPoint_position = thisMeterData.measureIndex + 1;
				}
				
				thisMeterData = null;
				thisMeterEndTimingPoint = null;
				thisMeterEndTimingPoint_offset = NaN
				thisMeterEndTimingPoint_position = NaN
			}
		}
		
		private function setMeterData2(data:Data):void
		{
			// 在走到下一个小节的时候清空最后的节拍。
			// 保证节拍数据只会作用于本小节。
			if (thisMeterData
			&&  thisMeterData.measureIndex < data.measureIndex) // 如果节拍的下一小节没有数据呢？
			{
				// 走到了从最后节拍数据开始之后的小节。
				// 如果紧接的下一个小节还有继续节拍，当前后的节拍数值都一样的，就继续这个TimingPoint，不做修改。
				if (nextMeterData
				&&  nextMeterData.measureIndex == thisMeterData.measureIndex + 1
				&&  thisMeterData.content == nextMeterData.content)
				{
					thisMeterData = nextMeterData;
					nextMeterData = null;
					return;
				}
				
//				// 节拍小节的下一个小节没有数据，跳了小节。
//				// 这时候直接处理接下来的数据的话，offset不对，应要先在上一个节拍结束的地方加TimingPoint。
//				if (data.measureIndex !== thisMeterData.measureIndex + 1)
//				{
//					// 给上一个节拍结束的地方加TimingPoint。
//				}
				
				// 在上一个小节终止处加TP。
				var tp:TimingPoint = new TimingPoint();
				var offset:Number = lastBPMData ?
					getOffset2(data, lastBPMData, thisMeterData) :
					0;
				// --- 停止处 ---
				
//				// 下一个小节的第0号物件全部解析完才处理节拍。
//				if (data.index < 1)
//					return;
				
				// 接下来的一个小节没有节拍通道。
				// 如果没有新BPM加了TimingPoint，就在上一个小节终止处加一个TimingPoint(inherited)，不然就修改TimingPoint。
				// 为什么这里的终止节拍小节不能和上面的合并？明明可以啊！
				// 不要想着measureTime错了，那是这个小节的，不是上个小节的，而index为0。只要有上一个TimingPoint的offset就没问题。
				// 但是还有个BPM通道，如果在解析BPM通道之前加了TP，而刚好这里有BPM8的话…… time要再 * meter。
				// 对啊，在有节拍通道的小节里，BPM转的TP都得time *= meter。
				// 现在是直接加TP。
//				if (thisMeterData.measureIndex === lastBPMData.measureIndex + 1
//				&&  lastBPMData.index === 0)
//				{
//				var tp:TimingPoint = new TimingPoint();
//				// BPM一定会在节拍前有出现过。
//				//					var offset:Number = lastBPMData ?
//				//						getOffset2(data, lastBPMData, thisMeterData) :
//				//						0;
//				var offset:Number = getOffset2(thisMeterData, lastBPMData, thisMeterData);
//				tp.offset = Math.round(offset);
//				tp.time = getUnknownTimeByMeter(thisMeterData, lastBPM3Data);
//				tp.type = TimingPoint.TYPE_INHERITED;
//				
//				lastTimingPoint_offset = offset;
//				thisMeterTimingPoint = tp;
//				
//				osu.timingPoints.push(tp);
//				
//				thisMeterData = null;
//				}
			}
		}
		
		private function convertBPM(data:Data):void
		{
			// 开始转。
			const tp:TimingPoint = new TimingPoint();
			const offset:Number = lastBPMData ?
//				getOffset2(data, lastBPMData, thisMeterData) :
				getOffset3(data) :
				0;
			tp.offset = Math.round(offset);
			if (data.channel === BMS.CHANNEL_BPM)
			{
				tp.time = MINUTE / data.content;
				tp.type = TimingPoint.TYPE_TIMING;
				
				lastBPM3Data = data;
				
				lastRedTimingPoint_bpm = data.content;
			}
			else if (data.channel === BMS.CHANNEL_BPM_EXTENDED)
			{
				// BPM 一定会在 BPM_EXTENDED 之前出现，lastBPM3Data 就不用判断了。没有的话，我也要让他有！
				tp.time = getUnknownTime(data);
				tp.type = TimingPoint.TYPE_INHERITED;
				
				// 判断超变速的话稍微处理一下，因为这不是 Timing tp，
				// 不会跟下面那段和 meter tp 重叠删除什么的冲突，大概。
				if (Math.round(tp.time) == 0) // 如果是超变速（瞬间突降），
				{
					// 提前 1ms，这是我试出来这样子设置才可以，
					// 不然2个相同 offset 的 tp 重叠的话什么也没有发生，
					// 大概是被“覆盖”了吧。
					tp.offset -= 1;
				}
			}
			else
				throw new Error('未知的 BPM channel：' + data.channel);
			
			// 这里要在 lastBPMData 改变之前先用之前的 bpm 给这个小节的 meter 算时间。
			if (thisMeterEndTimingPoint)
			{
				const position:Number = data.measureIndex + data.index / data.length;
				// meter 结束 tp 参照的是最后的 tp，小节内有 bpm 改变了的话要参照它。
				thisMeterEndTimingPoint.time = MINUTE /
					(data.channel === BMS.CHANNEL_BPM ? // 判断是 BPM 还是 BPM_EXTENDED。
					data.content :
					bms.bpms[lastBPMData.content]);
				// 增加 meter end tp 的 offset。
				thisMeterEndTimingPoint_offset +=
					getMeasureTime(lastBPMData, thisMeterData) * (position - thisMeterEndTimingPoint_position);
				// 改变 meter end tp 的参照 position。
				thisMeterEndTimingPoint_position = position;
			}
			
			// TODO: 可以不要下面这一段，直接在 :275 左右的 .delayOperation() 之后建一个函数，
			// 删除所有 tp 中相同 offset 和 type 的 tp。
			
			// 如果要放 tp 的地方已经有一个相同 offset 的 tp（可能是 meter 创建的），
			// 那么就把它删了。防止 osu 的 Timing Point 在 offset 相同时按文本倒序
			// 加载的 bug。
			const tps:Vector.<TimingPoint> = osu.timingPoints;
			if (tps.length > 0)
			{
				const lastTp:TimingPoint = tps[tps.length - 1];
				// 只要看最后一个 tp 即可，因为最后一个即是 offset 最大的，才有可能相同。
				if (tps.length > 0 && lastTp.offset == tp.offset && lastTp.type == tp.type)
					tps.splice(tps.length - 1, 1);
			}
			
			// 这句话不包括在上面说的“下面这一段”哦！
			tps.push(tp);
			lastBPMData = data;
			lastTimingPoint = tp;
			lastTimingPoint_offset = offset;
			lastTimingPoint_position = data.measureIndex + data.index / data.length;
		}
		
		private function getPrevTimingPoint(index:uint, type:uint):TimingPoint
		{
			// 从后往前找第一个 TimingPoint。
			const timingPoints:Vector.<TimingPoint> = osu.timingPoints;
			for (var i:int = index; i > 0 ; i--) 
			{
				var tp:TimingPoint = timingPoints[i];
				if (tp.type === type)
					return tp;
			}
			
			throw new Error('竟然没有之前的 TimingPoint？');
			return null;
		}
		
		private function convertMeter(data:Data):void
		{
			// 创建起始 TP。
			const tp:TimingPoint = new TimingPoint();
//			var offset:Number = getOffset2(data, lastBPMData, thisMeterData);
			const offset:Number = getOffset3(data);
			const thisBPM:Number = getThisBPM();
			
			tp.offset = Math.round(offset);
			// 现在我把 :583 这一句和 :598 这一句的 lastBPMData 用 lastBPM3Data 代替，试试行不行。
			// 再次修改，换成了获取最后 bpm 的，这个才是正确的，但是 d 什么那个谱又 99598*** 了。
			tp.time = MINUTE / thisBPM; // 原来这里原来就错了，一直就是错的，后来被转 bpm 的函数删掉了所以没影响？
			tp.type = TimingPoint.TYPE_TIMING;
//			tp.time = getUnknownTimeByMeter(data, lastBPM3Data);
//			tp.type = TimingPoint.TYPE_INHERITED;
			
			osu.timingPoints.push(tp);
			thisMeterData = data;
			lastTimingPoint = tp;
			lastTimingPoint_offset = offset;
			lastTimingPoint_position = data.measureIndex;
			lastRedTimingPoint_bpm = thisBPM;
			
			// 缓存终止 TP。这时候参照的 offset 是上面的那个哟。
			
			// 后面发现这样不对的。那只能先存这个起始 tp 的 offset，
			// 然后在这个小节内如果发现 bpm，就给 offset 加时间，
			// 到小节尾的时候，再算与最后一个 bpm（没有的话就小节头）相隔的时间。
			const endTp:TimingPoint = new TimingPoint();
//			const endTp_offset:Number = getMeasureTime(lastBPMData, thisMeterData) + offset;
//			endTp.offset = Math.round(endTp_offset);
			endTp.time = MINUTE / getThisBPM();
			endTp.type = TimingPoint.TYPE_TIMING;
			
			thisMeterEndTimingPoint = endTp;
			thisMeterEndTimingPoint_offset = offset;
			thisMeterEndTimingPoint_position = data.measureIndex + data.index / data.length;
		}
		
		/**
		 * 使之后的整个谱面数据暂停（延后）一段时间。
		 * 不受 meter 的影响，都是 *4！
		 */
		private function convertStop(data:Data):void
		{
			// 加一个起始 tp 停止开始。
			const tp:TimingPoint = new TimingPoint();
			const offset:Number = getOffset3(data);
			tp.offset = Math.round(offset);
			tp.time = STOP_TIME;
			tp.type = TimingPoint.TYPE_TIMING;
			
			// 加一个结束 tp 停止结束。原本是这么想的。
			// 但是如果最后一个 tp 是变速（由 BPM_EXTENDED 转来），
			// 需要先加原 BPM 的 tp（timing），再加变速 tp（inherited），
			// 并且为了防止 osu 的 tp 重叠 bug，如果和开始停止的 tp.offset 一样的话把变速 tp 删了。
			const tps:Vector.<TimingPoint> = osu.timingPoints;
			const endTp:TimingPoint = new TimingPoint();
			var endTp2:TimingPoint; // 是变速的情况，附加的 TimingPoint.TYPE_TIMING。
			const stopTime:Number = getStopTime(data);
			const offset2:Number = offset + stopTime
			if (lastTimingPoint.type == TimingPoint.TYPE_TIMING) // 不是变速
			{
				endTp.offset = Math.round(offset2);
				endTp.time = lastTimingPoint.time;
				endTp.type = TimingPoint.TYPE_TIMING;
				tps.push(tp, endTp);
			}
			else // 是变速
			{
				// 为了防止 osu 的 tp 重叠 bug，如果和开始停止的 tp.offset 一样的话把变速 tp 删了。
				if (lastTimingPoint.offset == tp.offset)
					tps.splice(tps.length - 1, 1); // 删去最后一个，即那个变速 tp。
				
				endTp2 = new TimingPoint();
				
				// endTp 为变速 tp。
				endTp.offset = endTp2.offset = Math.round(offset2);
				endTp.time = lastTimingPoint.time;
				endTp.type = lastTimingPoint.type;
				
				// endTp2 为 Timing tp。
				endTp2.time = MINUTE / lastBPM3Data.content;
				endTp2.type = TimingPoint.TYPE_TIMING;
				
				tps.push(tp, endTp2, endTp); // 是先 endTp2 再 endTp，TIMING 要在 INHERITED 的后面。
			}
			
			lastTimingPoint = endTp;
			lastTimingPoint_offset = offset + stopTime;
			lastTimingPoint_position = data.measureIndex + data.index / data.length;
			
			// 重新调整（延后） meter 结束 tp 的 offset。
			if (thisMeterEndTimingPoint)
				thisMeterEndTimingPoint_offset = thisMeterEndTimingPoint_offset + stopTime; 
		}
		
		private function convertBGM(data:Data):void
		{
			const sound:Sound = new Sound();
//			sound.offset = Math.round(getOffset2(data, lastBPMData));
			sound.offset = Math.round(getOffset3(data));
			const path:String = bms.wavs[data.content];
			if (path)
				sound.file = PREFIX_SOUND_FILE + matchPath(path);
			
			osu.sounds.push(sound);
		}
		
		private function getPlayer(channel:uint):uint
		{
			// 先判断是玩家几。
			if ((10 < channel && channel < 20)
				||  (50 < channel && channel < 60))
				return 0;
			else if ((20 < channel && channel < 30)
				||  (60 < channel && channel < 70))
				return 1;
			else
				throw new Error('无法把bms轨道转换为对应的osu轨道，channel: ' + channel);
		}
		
		private function convertBGA(data:Data):void
		{
			// TODO: 调整好 offset。
			if (osu.video)
			{
//				throw new Error('有多个 video，只转一个 video 不行！');
			}
			else
			{
				const path:String = bms.bmps[data.content];
				if (path)
				{
					const re:RegExp = /\.(mpg|mpeg)$/i;
					
					if (re.test(path)) // 如果是 mpg 的格式，修改它的引用成能播的，文件转换在 Beatmap 里。
						osu.video = PREFIX_BMP_FILE + path.replace(re, FORMAT_CONVERT);
					else
						osu.video = PREFIX_BMP_FILE + path;
				}
			}
		}
		
		// TODO: 重构 .convertNote() 和 .convertLongNote()，在每个 note 上附加 按下/抬起 属性，这是作为中间者。
		// 全部 note 都创建完后，.print() 时再把它们全部连起来，可能这样子更好。
		
		private function convertNote(data:Data):void
		{
			const lane:uint = mapLane(data.channel);
			const player:uint = getPlayer(data.channel);
			const offset:uint = Math.round(getOffset3(data));
			
			// 有设定 lnobj 的 bms 为长音标模式。
			// 发现 ln 的结尾 data，把两头 data 处理成 ln 后交给 .convertLongNote() 处理。
			if (bms.lnobj && data.content == parseInt(bms.lnobj, 36))
			{
				// 把最后一个 note 转成 ln
				const lastNote:Note = lastNotes[player][lane];
				
				// 以下是错误的示范，如果把 Data 处理一下再转的话，有变速的情况下，对应的 TP 有可能会不对。
//				const lastData:Data = lastNote.data;
				
				// 所以需要直接把开头的 Note 转为 LN。
				const ln:LongNote = new LongNote(lastNote.data, data);
				ln.lane = lane;
				ln.player = player;
				ln.offset = lastNote.offset;
				ln.offset2 = offset;
				ln.sound = lastNote.sound;
				
				// note 的 channel + 40 就变为对应的 ln 的 channel
//				lastData.channel += 40;
//				data.channel += 40;
				
				osu.hitObjects.splice(osu.hitObjects.indexOf(lastNote), 1);
				osu.hitObjects.push(ln);
				
				delete lastNotes[player][lane];
				
//				convertLongNote(lastData);
//				convertLongNote(data);
			}
			else
			{
				const note:Note = new Note(data);
				note.lane = lane;
				note.player = player;
	//			note.offset1 = Math.round(getOffset2(data, lastBPMData, thisMeterData));
				note.offset = offset;
				setSound(note, data.content);
				
				osu.hitObjects.push(note);
				// 为了在长音标模式下能把前一个 note 和下一个 note 连成一个 ln。
				lastNotes[player][lane] = note;
			}
			
			// 简单地十位数用玩家索引，个位数用轨道。
			// 等会只会计算有几个元素所以是没问题的。
			keyCounter[player * 10 + lane] = true;
			if (lane == 0 && bms.extension != 'pms')
				haveScratch = true;
		}
		
		private function convertLongNote(data:Data):void
		{
			const lane:uint = mapLane(data.channel);
			const player:uint = getPlayer(data.channel);
			const offset:uint = Math.round(getOffset3(data));
//			var offset:uint = Math.round(getOffset2(data, lastBPMData, thisMeterData));
			
			// 一个节点按，一个节点放。
			var ln:LongNote;
			
			// 没有数组就创建
			if (!holdingLns[player])
				holdingLns[player] = [];
			
			if (holdingLns[player][lane])
			{
				trace('第 ' + lane + ' 道：按下状态');
				// 已经在按下状态：设置放开的 offset2 即完成，放入 hitObjects 数组。
				ln = holdingLns[player][lane];
				ln.data2 = data;
				ln.offset2 = offset;
				// TODO: 放开的音效加到sb音效中。
				
				osu.hitObjects.push(ln);
				
				delete holdingLns[player][lane];
			}
			else
			{
				trace('第 ' + lane + ' 道：放开状态');
				// 放开状态：新建一个 ln 并设置到此时的 offset。
				ln = new LongNote(data);
				ln.lane = lane;
				ln.player = player;
				ln.offset = offset;
				setSound(ln, data.content);
				
				holdingLns[player][lane] = ln;
			}
			
			// 简单地十位数用玩家索引，个位数用轨道。
			// 等会只会计算有几个元素所以是没问题的。
			keyCounter[player * 10 + lane] = true;
			if (lane === 0 && bms.extension != 'pms')
				haveScratch = true;
			
			trace('第 ' + lane + ' 道，offset: ' + offset);
		}
		
		private function setSound(hitObject:HitObject, content:uint):void
		{
			const sound:String = bms.wavs[content];
			if (sound)
			{
				hitObject.sound = PREFIX_SOUND_FILE + matchPath(sound);
				haveKeySound = true;
			}
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  Others
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		/**
		 * 后注：这个函数好像是在 BPM 通道不出现在最开头的时候用的，
		 * 避免 data 没有 lastBPM？ 来参照的问题。
		 * 解决方案：在最开头加上一个 BPM data，先转。
		 * 
		 * 后来发现如果 BPM data 也在开头的话，不会加，
		 * 但是这时候在它之前还有 data，转换的时候没有 lastBPM？ 参照报错，
		 * 所以 .isFirstTimingPointData() 判断如果有的话，直接先加上！（即不管它在不在开头，第一个转它(BPM)）
		 */
		private function addFirstTimingPointRedDataIfEmpty():void
		{
			// 寻找第一个 BPM 数据。
			var bpmData:Data;
			var measures:Array = bms.measures;
			var measures_length:uint = measures.length;
			measures:
			for (var i:int = 0; i < measures_length; i++) 
			{
				var measure:Vector.<Data> = measures[i];
				for each (var data:Data in measure) 
				{
					if (data.channel === BMS.CHANNEL_BPM)
					{
						// 如果有了就不用加了。<---错！详细看文档注释。
						// 直接加！
						if (isFirstTimingPointData(data))
						{
							convertBPM(data);
							// 加完当然要把它从里面删去，不然会加了2个在开头的相同的 tp。
							measure.splice(measure.indexOf(data), 1); 
							return;
						}
						
						// 没有就加。
						bpmData = data;
						break measures;
					}
					else if (data.channel === BMS.CHANNEL_BPM_EXTENDED)
					{
						// +++
						bpmData = data;
						break measures;
					}
				}
			}
			
			trace('没有第一个红线，加上加上。');
			
			var newData:Data = new Data();
			newData.channel = BMS.CHANNEL_BPM;
			newData.measureIndex = 0;
			newData.index = 0;
			newData.length = 1;
			newData.content = bms.bpm;
			
			// lastBPMData、lastBPM3Data 和 lastTimingPoint 都会在这里面被设置的不用担心。
			convertBPM(newData)
		}
		
		/**
		 * 最好不要。
		 */
		private function isFirstTimingPointData(data:Data):Boolean
		{
			return data.channel == BMS.CHANNEL_BPM
				&& data.measureIndex == 0
				&& data.index == 0 // 这一行为了解决在第一小节非索引0出现 bpm，不加红线的问题。
				// 然而实际上并没有遇到这个问题，可能是运气好，算是误打误撞发现了个隐藏 bug，需测试稳定！
				&& data.content !== 0;
		}
		
		/**
		 * 好帅的名字。
		 * 这里面设置依赖于 Key Count 的东西。
		 */
		private function delayOperations():void
		{
			// TODO: 按用户设置，是否清除默认音效。
			// 7k 很可能是 o2mania 的谱，去掉的是第七键。
			var doRemapHitObjects:Boolean =
				config.addNoScratch == '是' && haveScratch && osu.kc == 8;
//			trace('============================================');
//			trace('|                                          |');
//			trace('|             doRemapHitObjects:           |');
//			trace('|                                          |');
//			trace('|                                          |');
//			trace('|          ' + doRemapHitObjects + '             |');
//			trace('|                                          |');
//			trace('|    ' + bms.player + '                            |');
//			trace('|                                          |');
//			trace('|            ' + bms.name + '                    |');
//			trace('============================================');
			
			clearSounds();
			
			// 生成无皿谱。
			if (doRemapHitObjects)
			{
				const noScratchOSU:OSU = osu.clone();
				
				removeScratch(noScratchOSU);
				setNotePositions(noScratchOSU);
				beatmap.addOSU(noScratchOSU);
			}
			
			setNotePositions(osu);
		}
		
		private function clearSounds():void 
		{
			// 清除默认音效。
			for each (var obj:HitObject in osu.hitObjects) 
			{
				if (haveKeySound)
					obj.sound ||= 'clear';
			}
		}
		
		private function setNotePositions(osu:OSU):void
		{
			// 这里的 osu 是参数的 osu 而不是字段的 osu。
			// 为了 noScratchOSU 也可以复用。
			const keyCount:uint = osu.kc;
			for each (var obj:HitObject in osu.hitObjects) 
			{
				obj.setPosition(keyCount);
			}
		}
		
		private function removeScratch(noScratchOSU:OSU):void
		{
			haveScratch = false;
			noScratchOSU.kc -= 1;
			noScratchOSU.name = noScratchOSU.name = bms.name + '↓.' + bms.extension;
			noScratchOSU.version += '↓';
			
			const hitObjects:Vector.<HitObject> = noScratchOSU.hitObjects;
			
			var i:uint = 0;
			while (i < hitObjects.length)
			{
				// 如果没删除物件，则下一个索引。
				if (!remapHitObject(hitObjects[i]))
					i++;
			}
			
			/**
			 * 移除皿，并把轨道对应好。
			 * @return 表示是否移除了 HitObject。
			 */
			function remapHitObject(object:HitObject):Boolean
			{
				const hitObjects:Vector.<HitObject> = noScratchOSU.hitObjects;
				const player:uint = object.player;
				
				if (object.lane == 0)
				{
					hitObjects.splice(hitObjects.indexOf(object), 1);
					
					const sound:Sound = new Sound();
					sound.offset = object.offset;
					sound.file = object.sound;
					
					noScratchOSU.sounds.push(sound);
					return true;
				}
				
				// 只要把玩家1的轨道全部向前移一位即可，玩家2的皿的最右边。
//				if (player == 0)
				object.lane--;
				
				return false;
			}
		}
		
		private function setKeyCount():void
		{
			var keyCount:uint = 0;
			for each (var bool:Boolean in keyCounter) 
			{
				keyCount++;
			}
			
			osu.kc = keyCount;
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  Helper Function
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		private function getMeasureTime(bpmData:Data, meterData:Data = null):Number
		{
			// TP 的 time 和这个没关系。
			const num:Number = MINUTE / getThisBPM() * 4 * (meterData ? // 获取当前 meter，没有的话就是默认的 1。
				meterData.content : 1);
			return num;
		}
		
		private function getDistance(data:Data, prevData:Data):Number
		{
			const num:Number = data.measureIndex - prevData.measureIndex + data.index / data.length - prevData.index / prevData.length;
			return num;
		}
		
		private function getDistance2(data:Data):Number
		{
			const num:Number = data.measureIndex + data.index / data.length - lastTimingPoint_position;
			return num;
		}
		
		private function getOffset3(data:Data):Number
		{
			const num:Number = getMeasureTime(lastBPMData, thisMeterData) * getDistance2(data) + lastTimingPoint_offset;
			return num;
		}
		
		/**
		 */
		private function getOffset2(data:Data, prevBPMData:Data, _thisMeterData:Data = null):Number
		{
			const num:Number = getMeasureTime(prevBPMData, _thisMeterData)
				* getDistance(data, (_thisMeterData && data != _thisMeterData && _thisMeterData.measureIndex > prevBPMData.measureIndex) ?
					_thisMeterData :
					prevBPMData)
				+ lastTimingPoint_offset;
			return num
		}
		
		/**
		 * 获取到最后一个 meter 或 bpm。
		 */
		private function getLastTimingData():Data
		{
			if (thisMeterData && thisMeterData.measureIndex > lastBPMData.measureIndex + lastBPMData.index / lastBPMData.length)
				return thisMeterData;
			else
				return lastBPMData;
		}
		
		/**
		 * 获取谜之数值。
		 */
		private function getUnknownTime(bpm8Data:Data):Number
		{
			return -100 / (bms.bpms[bpm8Data.content] /
//				prevBPM3Data.content); // 这里不应该参照最后的 bpm3，如果 meter 在它后面就美丽。
				lastRedTimingPoint_bpm);
		}
		
		private function getUnknownTimeByMeter(meterData:Data, prevBPM3Data:Data):Number
		{
			return -100 / meterData.content;
		}
		
		/**
		 * @param barIndex 小节索引。
		 * @param index 这个小节的第几拍。
		 * @param length 这个小节总共有几拍。
		 */
		private function getOffset(measureIndex:uint, index:uint, length:uint):uint
		{
			// 四暗刻到除数为0的情况。
			// TODO: BMS拍数判断。换掉这个4 →→→↓
			return Math.round(60000 / osu.bpm * 4 * (measureIndex + (index === 0 ? 0 : index * 1 / length)));
		}
		
		private function getThisBPM():Number
		{
			return lastBPMData.channel == BMS.CHANNEL_BPM ? // 判断是 BPM 还是 BPM_EXTENDED。
				lastBPMData.content :
				bms.bpms[lastBPMData.content];
		}
		
		/**
		 * 延后的时间公式：(60000（一分钟毫秒数） / 60（BPM）)（每拍时间）* 4（拍） * 48（STOP值） / 192（最大节拍细分） == 1
		 * MINUTE / bpm * 4 * stop / MAX_DIVISION
		 * @see songs.bmses.BMS#CHANNEL_STOP
		 */
		private function getStopTime(data:Data):Number
		{
			const stopTime:Number = MINUTE /
				getThisBPM() *
				4 * bms.stops[data.content] / MAX_DIVISION;
			return stopTime;
		}
		
		private function mapLane(channel:uint):uint
		{
			if (bms.extension == 'pms')
				return LANE_MAP_PMS[channel];
			else
				return LANE_MAP_BMS[channel];
		}
		
		private function isVideo(name:String):Boolean
		{
			return RE_VIDEO.test(name);
		}
	}
}


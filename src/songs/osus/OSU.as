package songs.osus
{
	import flash.utils.ByteArray;
	
	import songs.bmses.BMS;

	/**
	 * 参考资料：
	 * http://tieba.baidu.com/p/2519854876
	 * http://tieba.baidu.com/p/2515386204
	 * http://tieba.baidu.com/p/2089899249
	 * https://osu.ppy.sh/forum/viewtopic.php?p=12468
	 * https://osu.ppy.sh/wiki/Osu_(file_format)
	 */
	public class OSU
	{
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Constructor
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function OSU(bms:BMS) // 为了深拷贝不出 ArgumentError。
		{
			this.bms = bms;
			bpm = bms.bpm;
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Variables
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  File
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public var name:String;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  General
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		internal var specialStyle:uint = 1;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  Metadata
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		internal var title:String;
		
		internal var titleUnicode:String;
		
		internal var artist:String;
		
		internal var artistUnicode:String;
		
		/**
		 * 我，蛤蛤。
		 */
		internal var creator:String = 'Satsuki Aoi';
		
		internal var version:String;
		
		public var source:String = '0133Trainer BMS';
		
		public var tags:String = 'bms conversion';
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  Difficulty
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		/**
		 * Circle Size 竟然是 Key Count？屁屁你坑爹！
		 */
		// TODO: kc 和 盘子分开。
		public var kc:Number = NaN;
		
		public var hp:Number = NaN;
		
		public var od:Number = NaN;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  Events
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		internal var background:String;
		
		internal var video:String;
		
		internal var sbBackgrounds:Vector.<SBBackground> = new <SBBackground>[];
		
		internal var sounds:Vector.<Sound> = new <Sound>[];
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  TimingPoints
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		internal var timingPoints:Vector.<TimingPoint> = new <TimingPoint>[];
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  HitObjects
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		internal var hitObjects:Vector.<HitObject> = new <HitObject>[];
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  BMS
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		internal var bms:BMS;
		
		internal var converter:BMS2OSUConverter;
		
		internal var printer:OSUPrinter;
		
		internal var bpm:Number = NaN;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Methods
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function print():String
		{
			printer ||= new OSUPrinter(this);
			return printer.print();
		}
		
		public function clone():OSU
		{
			const ba:ByteArray = new ByteArray();
			
			const osu:OSU = new OSU(bms);
			osu.name = name;
			osu.specialStyle = specialStyle;
			osu.title = title;
			osu.titleUnicode = titleUnicode;
			osu.artist = artist;
			osu.artistUnicode = artistUnicode;
			osu.creator = creator;
			osu.version = version;
			osu.source = source;
			osu.tags = tags;
			osu.kc = kc;
			osu.hp = hp;
			osu.od = od;
			osu.background = background;
			osu.video = video;
			
			osu.sbBackgrounds = new <SBBackground>[];
			for each (var sb:SBBackground in sbBackgrounds) 
			{
				osu.sbBackgrounds.push(sb.clone());
			}
			
			
			osu.sounds = new <Sound>[];
			for each (var sound:Sound in sounds) 
			{
				osu.sounds.push(sound.clone());
			}
			
			osu.timingPoints = new <TimingPoint>[];
			for each (var tp:TimingPoint in timingPoints) 
			{
				osu.timingPoints.push(tp.clone());
			}
			
			osu.hitObjects = new <HitObject>[];
			for each (var object:HitObject in hitObjects) 
			{
				if (object is Note)
					osu.hitObjects.push((object as Note).clone());
				else if (object is LongNote)
					osu.hitObjects.push((object as LongNote).clone());
				else
					throw new Error('奇怪的类型。');
					
			}
			
			
			osu.bms = bms;
			osu.converter = converter;
			osu.bpm = bpm;
			
			return osu;
		}
	}
}


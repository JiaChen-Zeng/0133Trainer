package songs.osus
{
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
		
		public function OSU(bms:BMS)
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
		
		public var source:String = 'BMS';
		
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
		
		internal var sbBackgrounds:Vector.<SBBackGround> = new <SBBackGround>[];
		
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
	}
}


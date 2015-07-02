package events
{
	import flash.events.Event;
	
	public class BMSEvent extends Event
	{
		public static const COLLECTING:String	= 'collecting';
		
		public static const COLLECTED:String	= 'collected';
		
		public static const LOADING:String		= 'loading';
		
		public static const LOADED:String		= 'loaded';
		
		public static const PARSING:String		= 'parsing';
		
		public static const PARSED:String		= 'parsed';
		
		public static const COPYING_OSU:String	= 'copying_osu';
		
		public static const COPYING_WAV:String	= 'copying_wav';
		
		public static const COPYING_BMP:String	= 'copying_bmp';
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Constructor
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function BMSEvent(type:String, res:String = null,
								 value:Number = NaN, total:Number = NaN)
		{
			super(type, bubbles, cancelable);
			_value = value;
			_total = total;
			_res = res;
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Properties
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		/** 正在加载的资源。 */
		private var _res:String;

		public function get res():String { return _res; }
		
		/** 当前的进度。 */
		private var _value:Number = NaN;

		public function get value():Number { return _value; }
		
		/** 总进度。 */
		private var _total:Number = NaN;
		
		public function get total():Number { return _total; }
	}
}


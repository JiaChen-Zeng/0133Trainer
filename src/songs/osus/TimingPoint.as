package songs.osus
{
	import mx.utils.StringUtil;

	public class TimingPoint
	{
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Constants
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  Sample
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		internal static const SAMPLE_NORMAL:uint	= 1;
		
		internal static const SAMPLE_SOFT:uint		= 2;
		
		internal static const SAMPLE_DRUM:uint		= 3;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  Line
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		internal static const TYPE_INHERITED:uint	= 0;
		
		internal static const TYPE_TIMING:uint		= 1;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Constructor
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function TimingPoint()
		{
			
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Variables
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		internal var offset:Number = NaN;
		
		/**
		 * 60000 / BPM。
		 * 原来 Beat 是一拍的时间，4 拍的话就要 *4。
		 * 
		 * TimingPoint 的这个数是 msPerBeat。
		 * InheritedPoint 的这个数是……谜之数值。msPerBeat = - lastTimingPoint.time * 谜之数值。
		 */
		// TODO: 看下 OSU 最多能取到几位小数。
		internal var time:Number = NaN;
		
		/**
		 * 每小节节拍数。
		 */
		internal var meter:uint = 4;
		
		/**
		 * 音效类别：1=Normal，2=Soft，3=Drum。
		 */
		internal var sample:uint = SAMPLE_SOFT;
		
		/**
		 * 自定义音效：0=默认。
		 */
		internal var sampleSet:uint = 0;
		
		internal var volume:uint = 70;
		
		internal var type:Number = NaN;
		
		internal var kiai:uint = 0;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Methods
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function toString():String
		{
			return StringUtil.substitute('{0},{1},{2},{3},{4},{5},{6},{7}',
				offset, time, meter, sample, sampleSet, volume, type, kiai);
		}
	}
}


package songs.osus
{
	import mx.utils.StringUtil;
	
	import songs.bmses.Data;

	public class LongNote extends HitObject
	{
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Constructor
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function LongNote(data:Data = null, data2:Data = null)
		{
			super(data);
			
			this.data2 = data2;
			
			objectFlag = HitObject.FLAG_LONG_NOTE;
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Variables
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		internal var data2:Data;
		
		internal var offset2:Number = NaN;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Methods
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function toString():String
		{
			return StringUtil.substitute('{0},{1},{2},{3},{4},{5}:{6}:{7}:{8}:{9}:{10}',
				x, y, offset, objectFlag, osuSound, offset2, osuSoundType, osuCustomSound, unknown, volume, sound || '');
		}
		
		public function clone():LongNote
		{
			const ln:LongNote = new LongNote(data);
			ln.lane = lane;
			ln.player = player;
			ln.x = x;
			ln.y = y;
			ln.offset = offset;
			ln.objectFlag = objectFlag;
			ln.osuSound = osuSound;
			ln.osuSoundType = osuSoundType;
			ln.osuCustomSound = osuCustomSound;
			ln.unknown = unknown;
			ln.volume = volume;
			ln.sound = sound;
			ln.data = data;
			
			ln.data2 = data2;
			ln.offset2 = offset2;
			
			return ln;
		}
	}
}


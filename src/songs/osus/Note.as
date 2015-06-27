package songs.osus
{
	import mx.utils.StringUtil;
	
	import songs.bmses.Data;

	public class Note extends HitObject
	{
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Constructor
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function Note(data:Data = null)
		{
			super(data);
			
			objectFlag = HitObject.FLAG_NOTE;
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Methods
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function toString():String
		{
			return StringUtil.substitute('{0},{1},{2},{3},{4},{5}:{6}:{7}:{8}:{9}',
				x, y, offset, objectFlag, osuSound, osuSoundType, osuCustomSound, unknown, volume, sound || '');
		}
		
		public function clone():Note
		{
			const note:Note = new Note(data);
			note.lane = lane;
			note.player = player;
			note.x = x;
			note.y = y;
			note.offset = offset;
			note.objectFlag = objectFlag;
			note.osuSound = osuSound;
			note.osuSoundType = osuSoundType;
			note.osuCustomSound = osuCustomSound;
			note.unknown = unknown;
			note.volume = volume;
			note.sound = sound;
			note.data = data;
			
			return note;
		}
	}
}


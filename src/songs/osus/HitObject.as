package songs.osus
{
	import songs.bmses.Data;

	public class HitObject
	{
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Class constants
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		internal static const FLAG_NOTE:uint = 1;
		internal static const FLAG_LONG_NOTE:uint = 128;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Constructor
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function HitObject(data:Data = null)
		{
			//在这里根据data初始化，不行！因为 convert*** 函数里太多需要判断的，有时不初始它也要获取到属性。
			this.data = data;
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Variables
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		/**
		 * 从零开始。
		 */
		internal var lane:Number = NaN;
		
		/**
		 * 从零开始。
		 */
		internal var player:Number = NaN;
		
		/**
		 * mania n 道对应坐标。（n 从零开始）
		 * x = 512 * (n + 0.5) / k（向下取整）
		 * y = 192
		 */
		internal var x:Number = NaN;
		
		internal var y:Number = NaN;
		
		/**
		 * 打击时间。
		 */
		internal var offset:Number = NaN;
		
		/**
		 * 音符类型：音符 = 1，长音符 = 128。
		 */
		internal var objectFlag:Number = NaN;
		
		/**
		 * Whistle、Clap 和 Finish 的，用不到。
		 */
		internal var osuSound:uint = 0;
		
		internal var osuSoundType:uint = 0;
		
		internal var osuCustomSound:uint = 0;
		
		internal var unknown:uint = 0;
		
		/**
		 * 0 是默认使用谱子设定声音。
		 */
		internal var volume:uint = 0;
		
		/**
		 * key 音文件名。
		 * 引用不存在的文件消除默认打击音效。
		 */
		internal var sound:String;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  Others
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		internal var data:Data;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Methods
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		/**
		 * 为何 O2Mania 的谱也能转？因为它去掉的是最后一个键——第七键，而不是皿！
		 */
		public function setPosition(keyCount:uint):void
		{
			if (keyCount == 9) // PMS
			{
				x = uint(512 * (lane + 0.5) / keyCount);
			}
			else // BMS
			{
				if (player === 0)
					x = uint(512 * (lane + 0.5) / keyCount);
				else if (player === 1)
				{
					// 第二玩家皿位在最右边。
					// 这里 - 0.5 其实是 0.5 - 1。
					// 因为皿位去掉了，要往前移一位。
					if (lane === 0)
						x = uint(512 * (keyCount - 0.5) / keyCount);
					else
						x = uint(512 * (lane + keyCount / 2 - 0.5) / keyCount);
				}
				else
					throw new Error('不存在的玩家索引：' + player);
			}
			
			y = 192;
		}
	}
}


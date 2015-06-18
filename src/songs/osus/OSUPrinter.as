package songs.osus
{
	internal final class OSUPrinter
	{
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Class constants
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		[Embed(source="assets/default.osu", mimeType="application/octet-stream")]
		internal static const TEMPLATE:Class;
		
		internal static const RE_VAR:RegExp = /{\w+}/g;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Constructor
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function OSUPrinter(osu:OSU)
		{
			this.osu = osu;
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Variables
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		private var osu:OSU;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Methods
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function print():String
		{
			var outputStr:String = String(new TEMPLATE());
			
			// 匹配出每个要替换的地方。
			var varArr:Array = outputStr.match(RE_VAR);
			var repArr:Vector.<String> = new Vector.<String>(varArr.length, true);
			
			// 取出要替换的字。
			var varArr_length:uint = varArr.length;
			for (var i:int = 0; i < varArr_length; i++) 
			{
				// 取 {} 中间的字。
				var key:String = varArr[i].slice(1, -1);
				
				// 如果是数组就把里面数据连起来，不是的话单个就OK。
				if (osu[key] is Vector.<*>)
				{
					var repStr:String = '';
					for each (var data:Object in osu[key]) 
					{
						repStr += data.toString() + '\r\n';
					}
					
					repArr[i] = repStr;
				}
				else
				{
					if (osu[key])
						repArr[i] = osu[key].toString();
				}
			}
			
//			trace(repArr);
			
			// TODO: 模板替换算法优化。
			var repArr_length:uint = repArr.length;
			for (var j:int = 0; j < repArr_length; j++) 
			{
				outputStr = outputStr.replace(new RegExp(varArr[j]), repArr[j] || '');
			}
			
			return outputStr;
		}
	}
}


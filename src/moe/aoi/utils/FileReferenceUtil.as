package moe.aoi.utils
{
	import flash.net.FileReference;

	public class FileReferenceUtil
	{
		public static function getBaseName(fileReference:FileReference):String
		{
			var extension:String = fileReference.extension;
			var fullName:String = fileReference.name;
			
			//没有后缀名直接返回
			if (extension == null)
				return fullName;
			
			//有后缀名截取前面的返回
			var index:int = fullName.lastIndexOf('.' + extension);
			var name:String = fullName.slice(0, index);
			return name;
		}
		
		public static function filterName(fileName:String, replaceString:String = ''):String
		{
			const re:RegExp = /[\\\/:*?"<>|]/g;
			return fileName.replace(re, replaceString);
		}
	}
}
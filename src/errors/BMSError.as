package errors 
{
	/**
	 * 关于 BMS 的各种错误
	 * @author 彩月葵☆彡
	 */
	public final class BMSError extends Error 
	{
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Class constants
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public static const HEADER_ERROR:String = '解析 BMS 头时出现错误：'
		
		public static const PARSE_ERROR:String = '解析 BMS 谱面时出现错误：';
		
		public static const MATCHNAME_ERROR:String = '在尝试匹配出 BMS 曲包名字时出现错误：';
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Constructor
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function BMSError(message:String, error:Error) 
		{
			this.message = message;
			_error = error;
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Properties
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		/**
		 * 详细的错误，== 看看如果已经能看到详细的错误的话就不用这个了啦
		 */
		private var _error:Error;
		
		public function get error():Error { return _error; }
	}

}
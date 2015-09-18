package moe.aoi.utils
{
	/**
	 * ...
	 * @author 彩月葵☆彡
	 */
	internal class ChainBase 
	{
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Constructor
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function ChainBase(source:Vector.<*>):void 
		{
			_source = source;
			_length = _source.length;
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Variables
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		/**
		 * 要对数据源做的操作函数，会传入对象
		 */
		public var func:Function;
		
		// TODO: 其实这个可以用 done(function(){}) 代替，又涉及包管理的问题，还是看看不用这个吧
		/**
		 * 在对象身上调用方法
		 */
		public var method:String;
		
		/**
		 * 完成时调用的函数
		 */
		public var done:Function;
		
		/**
		 * 错误时调用的函数
		 */
		public var fail:Function;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Properties
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		/**
		 * 数据源
		 */
		private var _source:Vector.<*>;
		
		public function get source():Vector.<*> { return _source; }
		
		/**
		 * 要处理的对象
		 */
		private var _list:Vector.<*>;
		
		public function get list():Vector.<*> { return _list; }
		
		/**
		 * 出现错误失败的对象
		 */
		private var _errorList:Vector.<*>;
		
		public function get errorList():Vector.<*> { return _errorList; }
		
		/**
		 * 要处理，或正在处理的对象的索引
		 */
		protected var _index:uint;
		
		public function get index():uint { return _index; }
		
		/**
		 * 源对象的长度
		 */
		protected var _length:uint;
		
		public function get length():uint { return _length; }
		
		/**
		 * 要处理，或正在处理的对象
		 */
		public function get object():* { return _source[_index]; }
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Methods
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		private function init():void 
		{
			// 预设
			_index = 0;
			
			// 初始化 list 为跟 source 一样内容
			_list = new Vector.<*>();
			for (var i:uint = 0; i < _length; i++) 
			{
				_list[i] = _source[i];
			}
			
			// 初始化 errorList
			_errorList = new Vector.<*>();
		}
		
		protected function execute():void 
		{
			try 
			{
				func(object);
			}
			catch (error:*)
			{
				this.error();
				fail(error);
			}
		}
		
		/**
		 * 按 source 一个一个对象处理
		 */
		public function start():void 
		{
			init();
			resume();
		}
		
		public function resume():void 
		{
			
		}
		
		/**
		 * 把正在处理的对象移入错误列表。在执行代码发生错误时会自动调用此方法。
		 */
		public function error():void 
		{
			_list.splice(index, 1);
			_errorList.push(_source.slice(index, index + 1)[0]);
		}
	}
}
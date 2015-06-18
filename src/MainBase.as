package
{
	import mx.core.IVisualElement;
	
	import spark.components.Group;
	import spark.components.WindowedApplication;
	
	public class MainBase extends WindowedApplication
	{
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Constructor
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function MainBase()
		{
			super();
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Variables
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  SkinParts
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		[SkinPart]
		public var headerGroup:Group;
		
		[SkinPart]
		public var footerGroup:Group;
		
		[SkinPart]
		public var leftSideGroup:Group;
		
		[SkinPart]
		public var rightSideGroup:Group;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Properties
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  header
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		[ArrayElementType("mx.core.IVisualElement")]
		private var _header:Array;
		
		public function get header():Array { return _header; }
		
		public function set header(value:Array):void
		{
			_header = value;
			if (headerGroup)
				headerGroup.mxmlContent = value;
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  footer
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		[ArrayElementType("mx.core.IVisualElement")]
		private var _footer:Array;
		
		public function get footer():Array { return _footer; }
		
		public function set footer(value:Array):void
		{
			_footer = value;
			if (footerGroup)
				footerGroup.mxmlContent = value;
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  header
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		[ArrayElementType("mx.core.IVisualElement")]
		private var _leftSide:Array;
		
		public function get leftSide():Array { return _leftSide; }
		
		public function set leftSide(value:Array):void
		{
			_leftSide = value;
			if (leftSideGroup)
				leftSideGroup.mxmlContent = value;
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  header
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		[ArrayElementType("mx.core.IVisualElement")]
		private var _rightSide:Array;
		
		public function get rightSide():Array { return _rightSide; }
		
		public function set rightSide(value:Array):void
		{
			_rightSide = value;
			if (rightSide)
				rightSide.mxmlContent = value;
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Overridden methods
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		override protected function partAdded(partName:String, instance:Object):void
		{
			super.partAdded(partName, instance);
			
			switch (instance)
			{
				case headerGroup:		headerGroup.mxmlContent		= _header;		break;
				case footerGroup:		footerGroup.mxmlContent		= _footer;		break;
				case leftSideGroup:		leftSideGroup.mxmlContent	= _leftSide;	break;
				case rightSideGroup:	rightSideGroup.mxmlContent	= _rightSide;	break;
			}
		}
	}
}


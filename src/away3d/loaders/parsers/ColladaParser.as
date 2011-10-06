package away3d.loaders.parsers {
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Geometry;
	import away3d.core.base.SubGeometry;
	import away3d.entities.Mesh;
	import away3d.loaders.misc.ResourceDependency;
	import away3d.library.assets.AssetType;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;	
	import flash.utils.Dictionary;
	
	use namespace arcane;
	/**
	 * provides a parser for the Collada (DAE) data type.
	 */
	public class ColladaParser extends ParserBase{
		
		//XML
		private var _count:int;						// number of parsed libary elements
		private var _doc:XML;						// the Collada file
		private var _ns:Namespace;					// xml namespace of the Collada file
		private var _current:Mesh;					// current mesh
		private var _parent:ObjectContainer3D;		// parent of the current mesh
		private var _scale:Number;					// global scale factor
		private var _state:int;						// state of the parser
		private var _temp:Array;					// temporary array
		private var _uvs:Boolean;					// texture parsed?
		private var _normals:Boolean;				// normals parsed?
		//Asset
		private var _yUp:Boolean;					// up axis
		//Visual scene	
		private var _geomNames:Dictionary;			// contains all nodes of a visual scene which have a geometry instance
		private var _matrix:Matrix3D;				// temporary matrix needed for transformation
		private var _scene:ObjectContainer3D;		// root object of a scene graph
		private var _transform:Matrix3D;			// temporary matrix needed for transformation
		private var _vscene:XMLList;				// the visual scene
		//Geometry
		private var _geomLib:XMLList;				// the geometry libary
		private var _dataVertex:Vector.<Number>;	// vertexBuffer of a geometry
		private var _dataNormal:Vector.<Number>;	// normalBuffer data of a geometry
		private var _dataUV:Vector.<Number>;		// uvBuffer of a geometry
		private var _index:uint;					// index to the indexBuffer
		private var _indices:Vector.<uint>;			// indexBuffer of a geometry
		private var _inputVertexId:String;			// id of the input element containing the vertex data
		private var _inputNormalId:String; 			// id of the input element containing the normal data
		private var _inputUVId:String;				// id of the input element containing the uv data	
		private var _numberInputs:int;				// amount of input elements of a geometry element
		private var _offsetVertex:int;				// offset of the input element containing the vertex data
		private var _offsetNormal:int;				// offset of the input element containing the normal data
		private var _offsetUV:int;					// offset of the input element containing the uv data
		private var _sub_geom:SubGeometry;			// result of a parsed geometry element
		private var _vcount:Array;					// array containing the vcount element of a polylist
		private var _verticsSource:String;			// source attribute of a vertics element
		private var _verticsSemantic:String;		// semantic attribute of a vertics element
		private var _sources:Dictionary;			// source elements of a geomerty
		private var _dic:Dictionary;				// contains points of a geomerty element with unique vertex normal uv pairs
		
		public function ColladaParser(scale:Number = 1, normals:Boolean = false, uvs:Boolean = false) {
			super(ParserDataFormat.PLAIN_TEXT);
			_scale = scale;
			_yUp = false;
			_normals = normals;
			_uvs = uvs;
			_state = 0;	
			_transform = new Matrix3D();
			_matrix = new Matrix3D();
			_vcount = [];
			_temp = [];
			_geomNames = new Dictionary();
		}
		
		/**
		 * Indicates whether or not a given file extension is supported by the parser.
		 * @param extension The file extension of a potential file to be parsed.
		 * @return Whether or not the given file type is supported.
		 */
		public static function supportsType(extension : String) : Boolean {
			extension = extension.toLowerCase();
			return extension == "dae";
		}
		
		/**
		 * Tests whether a data block can be parsed by the parser.
		 * @param data The data block to potentially be parsed.
		 * @return Whether or not the given data is supported.
		 */
		public static function supportsData(data : *) : Boolean {
			//ToDO
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function resolveDependency(resourceDependency:ResourceDependency):void {
			//ToDo
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function resolveDependencyFailure(resourceDependency:ResourceDependency):void {			
			//ToDo
		}
			
		/**
		 * @inheritDoc
		 */
		protected override function proceedParsing() : Boolean {
			while (hasTime()) {
				// load xml file
				if (_state == 0) {
					_doc = new XML(getTextData());
					_ns = _doc.namespace();
					_state++;
				}
				//parse asset
				else if (_state == 1) {
					parseAsset(_doc._ns::asset.children());
					_state++;
				}
				//parse visual scene
				else if (_state == 2) {
					if (!_vscene) {
						_vscene = _doc._ns::library_visual_scenes.children().children();
						_scene = new ObjectContainer3D();
						_scene.name = "scene";
						finalizeAsset(_scene, _scene.name);
						_count = 0;
					}
					
					_parent = _scene;
					parseNode(_vscene[_count]);
					
					if(_vscene.length()-1 == _count){
						_state++;
					}else {
						_count++;
					}
				}
				//parse library_geometries
				else if (_state == 3 ) {	
					if (!_geomLib) {
						_geomLib = _doc._ns::library_geometries.children();
						_count = 0;
					}
					_current = _geomNames[_geomLib[_count].attribute("id").toString()];	
					if(parseGeometry(_geomLib[_count])){
						_current.geometry.addSubGeometry(_sub_geom);
						finalizeAsset(_current, _current.name);
					}
					
					if (_geomLib.length() - 1 == _count) {
						_state++;
					}else {
						_count++;
					}				
				}
				//parsing done
				else if (_state == 4 ) {
					return PARSING_DONE;
				}
			}
			return MORE_TO_PARSE;
		}
		
		/**
		 * Parses the asset element of a Collada file
		 * @param asset The asset element
		 */
		private function parseAsset(asset:XMLList) : void {
			for each(var node:XML in asset) {
				switch(node.localName()) {
					case "contributor":
						break;
					case "coverage":
						break;
					case "created":
						break;
					case "keywords":
						break;
					case "modified":
						break;
					case "revision":
						break;
					case "subject":
						break;
					case "title":
						break;
					case "unit":
						break;
					case "up_axis":
						if (node == "Y_UP") {
							_yUp = true;
						}
						break;
					case "extra":
						break;
					default:
						//Error
						return;
				}//switch
			}//for
		}//parseAsset
		
		/**
		 * Parses a geometry element of the geometries library (supports only polylist)
		 * @param geom The geometry element
		 * @return Whether or not the geometry could be parsed
		 */
		private function parseGeometry(geom:XML) : Boolean {
			_sub_geom = new SubGeometry();
			_sub_geom.autoDeriveVertexNormals = false;
			_sub_geom.autoDeriveVertexTangents = true;
			_dic = new Dictionary();
			_sources = new Dictionary();
			_numberInputs = 0;
			for each(var node:XML in geom.children().children()) {
				switch(node.localName()) {
					case "source":
						parseSource(node.attribute("id"), node.children());
						break;
					case "vertices":
						parseVertics(node.children());
						break;
					case "polylist":
						parsePolyList(node.children());
						break;
					default:
						//Error
						_current.parent.removeChild(_current);
						return false;
				}//switch
			}//for	
			_sub_geom.updateVertexData(_dataVertex);
			if (_normals) {
				_sub_geom.updateVertexNormalData(_dataNormal);		
			}else {
				_sub_geom.autoDeriveVertexNormals = true;
			}
			if (_uvs) {
				_sub_geom.updateUVData(_dataUV);
			}
			_sub_geom.updateIndexData(_indices);
			return true;
		}//parseGeometry
		
		/**
		 * Parses a source element of a geometry element
		 * @param source The source element
		 */
		private function parseSource(id:String, source:XMLList) : void {
			for each(var node:XML in source) {
				switch(node.localName()) {
					case "float_array":
						_temp = node.toString().split(/\s+/);
						break;
					case "technique_common":
						break;
					default :
						//Error
						break;	
				}
			}
			_sources[id] = _temp;
		}
		
		/**
		 * Parses a vertics element of a geometry element
		 * @param vertices The vertics element
		 */
		private function parseVertics(vertices:XMLList): void {
			for each(var node:XML in vertices) {
				if (node.localName() == "input") {
					_verticsSemantic = node.attribute("semantic");
					_verticsSource = node.attribute("source");
					_verticsSource = _verticsSource.substring( 1, _verticsSource.length );
				}
			}
		}
		
		/**
		 * Parses a polylist element of a geometry element
		 * @param poly The polylist element
		 */
		private function parsePolyList(poly:XMLList): void {
			_index = 0;
			_indices = new Vector.<uint>();
			_dataVertex = new Vector.<Number>();
			if (_normals) _dataNormal = new Vector.<Number>();
			if (_uvs) _dataUV = new Vector.<Number>();	
			for each(var node:XML in poly) {
				switch (node.localName()) {
					case "input":
						parseInput(node);
						break;
					case "vcount":
						_vcount = node.toString().split(/\s+/);
						break;
					case "p":
						_temp = node.toString().split(/\s+/);		
						var ind:uint = 0;
						var i:uint;
						var offset:uint;
						for each (var v:int in _vcount) {
							offset = 1;
							for (i = 0; i < v - 2;i++) {
								createVertex(ind);
								createVertex(ind + offset +1);
								createVertex(ind + offset);
								offset++;
							}
							ind += v;
						}
						break;
					case "extra":
						break;
					default: 
						//Error
						return;
				}//switch
			}//for
		}//parsePolyList
		
		/**
		 * Creates a vertex
		 * @param ind The index in the polylist
		 */
		private function createVertex(ind:uint):void {
			var v:uint, n:uint, u:uint;
			v = _temp[ind * _numberInputs + _offsetVertex];
			var key:String = "" + v;
			if (_normals) {
				n = _temp[ind * _numberInputs + _offsetNormal];
				key += "_" + n;
			}
			if (_uvs) {
				u = _temp[ind * _numberInputs + _offsetUV];
				key += "_" + u;
			}
			
			if (_dic[key] != null) {
					_indices.push(_dic[key]);
			}else {
				_dic[key] = _index;
				_indices.push(_index);
				if (_yUp) {
					_dataVertex.push( _sources[_verticsSource][v * 3] * -_scale);
					_dataVertex.push( _sources[_verticsSource][v * 3 + 1] * _scale);
					_dataVertex.push( _sources[_verticsSource][v * 3 + 2] * _scale);
				}else {
					_dataVertex.push( _sources[_verticsSource][v * 3] * _scale);
					_dataVertex.push( _sources[_verticsSource][v * 3 + 1] * -_scale);
					_dataVertex.push( _sources[_verticsSource][v * 3 + 2] * -_scale);
				}
				if (_normals) {
					_dataNormal.push(_sources[_inputNormalId][n * 3]);
					_dataNormal.push(_sources[_inputNormalId][n * 3 + 1]);
					_dataNormal.push(_sources[_inputNormalId][n * 3 + 2]);
				}
				if (_uvs) {
					_dataUV.push(_sources[_inputUVId][u * 2]);
					_dataUV.push(_sources[_inputUVId][u * 2 + 1]);
				}
				_index++;
			}
		}
		
		/**
		 * Parses a input element of a polylist element
		 * @param input The input element
		 */
		private function parseInput(input:XML) : void {
			switch ( input.attribute("semantic").toString() ) {
					case "VERTEX" :
						_inputVertexId = input.attribute("source");
						_inputVertexId = _inputVertexId.substring( 1, _inputVertexId.length );
						_offsetVertex = input.attribute("offset");
						break;
					case "NORMAL" :
						_inputNormalId = input.attribute("source");
						_inputNormalId = _inputNormalId.substring( 1, _inputNormalId.length );
						_offsetNormal = input.attribute("offset");
						break;
					case "TEXCOORD" :	
						_inputUVId = input.attribute("source");
						_inputUVId = _inputUVId.substring( 1, _inputUVId.length );
						_offsetUV = input.attribute("offset");
						break;
					default :
						//Error
						return;
			}
			_numberInputs++;
		}
		
		/**
		 * Parses a node element of a visual scene element
		 * @param node The node element
		 */
		private function parseNode(node:XML):void {
			var o:ObjectContainer3D;
			
			if (node._ns::instance_geometry.length() > 0) {
				o = new Mesh();
			}else {
				o = new ObjectContainer3D();
			}
			
			o.name = node.attribute("name").toString();
			_transform = o.transform;
			_parent.addChild(o);
			
			for each (var n:XML in node.children()) {	
				switch (n.localName()) {
					case "asset" :
						break;
					case "lookat" :
						break;
					case "matrix" :
						break;
					case "skew" :
						break;
					case "translate" :
						_temp = n.toString().split(/\s+/);
						_matrix.identity();
						if (_yUp){
							_matrix.appendTranslation(-_temp[0], _temp[1], _temp[2]);
						}else{
							_matrix.appendTranslation(_temp[0], _temp[2], _temp[1]);
						}	
						_transform.prepend(_matrix);
                        break;
					case "rotate" :
						_temp = n.toString().split(/\s+/);
						_matrix.identity();
						if (_yUp){
							_matrix.appendRotation(_temp[3], new Vector3D(_temp[0], -_temp[1], -_temp[2]));
						}else{
							_matrix.appendRotation( -_temp[3], new Vector3D(_temp[0], _temp[2], _temp[1]));
						}	
						_transform.prepend(_matrix);
						break;
					case "scale" :
						break;
					case "instance_camera" :
						break;
					case "instance_controller" :
						break;
					case "instance_geometry" :
						var url:String = n.attribute("url");
						_geomNames[ url.substring( 1,  url.length) ] = o;
						break;
					case "instance_light" :
						break;
					case "instance_node" :
						break;
					case "node" :
						_parent = o;
						parseNode(n);
						break;
					case "extra" :
						break;
					default :
						//Error
						return;
				}//switch
			}//for
			if(o.assetType == AssetType.CONTAINER){
				finalizeAsset(o, o.name);
			}
		}//parseNode
	}//class
}//package
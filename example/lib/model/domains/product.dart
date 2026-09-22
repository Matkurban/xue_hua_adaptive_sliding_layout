class Product {
  ///商品 ID
  final int id;

  ///商品名称
  final String name;

  ///商品描述
  final String description;

  ///商品分类
  final String category;

  ///商品封面
  final String cover;

  ///商品图片
  final List<String> imgs;

  ///商品价格
  final double price;

  ///商品描述
  final String remark;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.cover,
    required this.imgs,
    required this.price,
    required this.remark,
  });
}

/// 商品分类列表
final List<String> mockCategories = [
  '3C数码',
  '居家生活',
  '服饰箱包',
  '美食酒饮',
  '运动户外',
  '办公文具',
];

/// 30 个商品数据集（图片采用稳定可用的 Picsum 图床种子源，保证多图不重复且高可用）
final List<Product> mockProducts = [
  // ================= 3C数码 (1-5) =================
  Product(
    id: 1,
    name: '无线降噪头戴耳机 Pro',
    description: '采用双重主动降噪技术，40mm高解析驱动单元，带来沉浸式声学体验。',
    category: '3C数码',
    cover: 'https://picsum.photos/seed/p1_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p1_img1/800/800',
      'https://picsum.photos/seed/p1_img2/800/800',
      'https://picsum.photos/seed/p1_img3/800/800',
    ],
    price: 1299.00,
    remark: '40小时超长续航 / 支持通透模式',
  ),
  Product(
    id: 2,
    name: '机械键盘 87键无线三模',
    description: '热插拔轴座设计，PBT双色注塑键帽，支持蓝牙、2.4G与有线三种连接方式。',
    category: '3C数码',
    cover: 'https://picsum.photos/seed/p2_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p2_img1/800/800',
      'https://picsum.photos/seed/p2_img2/800/800',
      'https://picsum.photos/seed/p2_img3/800/800',
    ],
    price: 459.00,
    remark: 'RGB幻彩背光 / Gasket消音结构',
  ),
  Product(
    id: 3,
    name: '智能运动健康手环 8',
    description: '1.62英寸高清全彩屏，支持血氧心率全天候监测，内置150+专业运动模式。',
    category: '3C数码',
    cover: 'https://picsum.photos/seed/p3_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p3_img1/800/800',
      'https://picsum.photos/seed/p3_img2/800/800',
      'https://picsum.photos/seed/p3_img3/800/800',
    ],
    price: 269.00,
    remark: '50米防水 / 磁吸快充续航16天',
  ),
  Product(
    id: 4,
    name: '65W 氮化镓超薄快充头',
    description: '采用最新第三代GaN黑科技芯片，折叠插脚便携设计，支持笔记本与手机快充。',
    category: '3C数码',
    cover: 'https://picsum.photos/seed/p4_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p4_img1/800/800',
      'https://picsum.photos/seed/p4_img2/800/800',
      'https://picsum.photos/seed/p4_img3/800/800',
    ],
    price: 119.00,
    remark: '双Type-C+USB-A三口输出',
  ),
  Product(
    id: 5,
    name: '便携式4K显示屏 15.6寸',
    description: 'IPS广视角面板，100% sRGB色域，Type-C一线直连Switch与笔记本。',
    category: '3C数码',
    cover: 'https://picsum.photos/seed/p5_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p5_img1/800/800',
      'https://picsum.photos/seed/p5_img2/800/800',
      'https://picsum.photos/seed/p5_img3/800/800',
    ],
    price: 999.00,
    remark: 'CNC铝合金机身 / 赠磁吸皮套',
  ),

  // ================= 居家生活 (6-10) =================
  Product(
    id: 6,
    name: '超声波静音香薰加湿器',
    description: '纳米级细雾扩散，夜灯柔光伴眠，缺水自动断电保护。',
    category: '居家生活',
    cover: 'https://picsum.photos/seed/p6_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p6_img1/800/800',
      'https://picsum.photos/seed/p6_img2/800/800',
      'https://picsum.photos/seed/p6_img3/800/800',
    ],
    price: 158.00,
    remark: '容量500ml / 适配各种水溶性精油',
  ),
  Product(
    id: 7,
    name: '慢回弹护颈记忆棉枕',
    description: '符合人体工学B型曲面造型，有效分散颈椎压力，四季温感不变形。',
    category: '居家生活',
    cover: 'https://picsum.photos/seed/p7_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p7_img1/800/800',
      'https://picsum.photos/seed/p7_img2/800/800',
      'https://picsum.photos/seed/p7_img3/800/800',
    ],
    price: 189.00,
    remark: '抗菌天丝枕套 / 可拆洗',
  ),
  Product(
    id: 8,
    name: '北欧极简实木床头台灯',
    description: '天然白蜡木底座搭配亚麻布艺灯罩，三档触摸无极调光。',
    category: '居家生活',
    cover: 'https://picsum.photos/seed/p8_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p8_img1/800/800',
      'https://picsum.photos/seed/p8_img2/800/800',
      'https://picsum.photos/seed/p8_img3/800/800',
    ],
    price: 139.00,
    remark: '无频闪护眼光源 / USB供电口',
  ),
  Product(
    id: 9,
    name: '智能恒温暖杯垫',
    description: '55度恒温保温，重力感应自动启停，适合马克杯、玻璃杯及盒装牛奶。',
    category: '居家生活',
    cover: 'https://picsum.photos/seed/p9_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p9_img1/800/800',
      'https://picsum.photos/seed/p9_img2/800/800',
      'https://picsum.photos/seed/p9_img3/800/800',
    ],
    price: 69.00,
    remark: '8小时自动关机 / 防溅水面板',
  ),
  Product(
    id: 10,
    name: '棉麻编织大号脏衣收纳篓',
    description: '环保棉麻粗绳编织，骨架挺括耐磨，带双侧便携提手。',
    category: '居家生活',
    cover: 'https://picsum.photos/seed/p10_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p10_img1/800/800',
      'https://picsum.photos/seed/p10_img2/800/800',
      'https://picsum.photos/seed/p10_img3/800/800',
    ],
    price: 79.00,
    remark: '容量约60L / 可折叠收纳',
  ),

  // ================= 服饰箱包 (11-15) =================
  Product(
    id: 11,
    name: '商务防泼水电脑双肩包',
    description: '高密度牛津布面料，独立加厚抗震电脑仓，最大可容纳16英寸游戏本。',
    category: '服饰箱包',
    cover: 'https://picsum.photos/seed/p11_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p11_img1/800/800',
      'https://picsum.photos/seed/p11_img2/800/800',
      'https://picsum.photos/seed/p11_img3/800/800',
    ],
    price: 299.00,
    remark: '透气蜂窝背垫 / 配备行李箱固定带',
  ),
  Product(
    id: 12,
    name: '头层牛皮复古折叠短款钱包',
    description: '精选手工头层植鞣牛皮，手感温润，内部多卡槽及大钞位合理布局。',
    category: '服饰箱包',
    cover: 'https://picsum.photos/seed/p12_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p12_img1/800/800',
      'https://picsum.photos/seed/p12_img2/800/800',
      'https://picsum.photos/seed/p12_img3/800/800',
    ],
    price: 168.00,
    remark: '内置RFID防盗刷屏蔽层',
  ),
  Product(
    id: 13,
    name: '260g重磅精梳纯棉打底T恤',
    description: '采用新疆长绒棉，紧密纺纱工艺，领口加固二本针罗纹不易变形。',
    category: '服饰箱包',
    cover: 'https://picsum.photos/seed/p13_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p13_img1/800/800',
      'https://picsum.photos/seed/p13_img2/800/800',
      'https://picsum.photos/seed/p13_img3/800/800',
    ],
    price: 89.00,
    remark: '多色可选 / 宽松落肩版型',
  ),
  Product(
    id: 14,
    name: '经典羊毛格纹保暖围巾',
    description: '100%精选澳洲美利奴羊毛，质地细腻软糯，流苏收边经典百搭。',
    category: '服饰箱包',
    cover: 'https://picsum.photos/seed/p14_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p14_img1/800/800',
      'https://picsum.photos/seed/p14_img2/800/800',
      'https://picsum.photos/seed/p14_img3/800/800',
    ],
    price: 219.00,
    remark: '尺寸200x35cm / 送礼盒包装',
  ),
  Product(
    id: 15,
    name: '轻量化复古慢跑运动鞋',
    description: 'EVA轻量高弹中底搭配耐磨橡胶大底，拼接反毛皮鞋面，透气舒适。',
    category: '服饰箱包',
    cover: 'https://picsum.photos/seed/p15_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p15_img1/800/800',
      'https://picsum.photos/seed/p15_img2/800/800',
      'https://picsum.photos/seed/p15_img3/800/800',
    ],
    price: 349.00,
    remark: '单只重约280g / 减震防滑',
  ),

  // ================= 美食酒饮 (16-20) =================
  Product(
    id: 16,
    name: '埃塞俄比亚耶加雪菲挂耳咖啡',
    description: '中浅度烘焙，带有清新的柑橘果香与茉莉花香气，口感明亮干净。',
    category: '美食酒饮',
    cover: 'https://picsum.photos/seed/p16_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p16_img1/800/800',
      'https://picsum.photos/seed/p16_img2/800/800',
      'https://picsum.photos/seed/p16_img3/800/800',
    ],
    price: 68.00,
    remark: '10g*10包/盒 / 充氮锁鲜保鲜',
  ),
  Product(
    id: 17,
    name: '武夷山原产特级大红袍礼盒',
    description: '传统炭焙工艺制作，岩韵醇厚悠长，茶汤红艳透亮，经久耐泡。',
    category: '美食酒饮',
    cover: 'https://picsum.photos/seed/p17_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p17_img1/800/800',
      'https://picsum.photos/seed/p17_img2/800/800',
      'https://picsum.photos/seed/p17_img3/800/800',
    ],
    price: 298.00,
    remark: '250g精致铁罐装 / 附赠礼袋',
  ),
  Product(
    id: 18,
    name: '原味混合每日坚果大礼包',
    description: '巴旦木、腰果、核桃仁配比蓝莓干与蔓越莓干，低温轻度烘烤不油腻。',
    category: '美食酒饮',
    cover: 'https://picsum.photos/seed/p18_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p18_img1/800/800',
      'https://picsum.photos/seed/p18_img2/800/800',
      'https://picsum.photos/seed/p18_img3/800/800',
    ],
    price: 99.00,
    remark: '25g*30袋 / 独立干湿分离锁鲜仓',
  ),
  Product(
    id: 19,
    name: '浑浊双倍IPA精酿啤酒 6听',
    description: '大量投放美系香型酒花，浓郁热带水果香气爆发，酒体醇厚细腻。',
    category: '美食酒饮',
    cover: 'https://picsum.photos/seed/p19_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p19_img1/800/800',
      'https://picsum.photos/seed/p19_img2/800/800',
      'https://picsum.photos/seed/p19_img3/800/800',
    ],
    price: 128.00,
    remark: '酒精度7.2%vol / 原麦汁浓度16.5°P',
  ),
  Product(
    id: 20,
    name: '85%可可纯黑无糖巧克力',
    description: '采用纯可可脂低温研磨工艺制作，苦甜平衡，入口丝滑不腻。',
    category: '美食酒饮',
    cover: 'https://picsum.photos/seed/p20_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p20_img1/800/800',
      'https://picsum.photos/seed/p20_img2/800/800',
      'https://picsum.photos/seed/p20_img3/800/800',
    ],
    price: 49.90,
    remark: '0蔗糖添加 / 生酮低碳健身友好',
  ),

  // ================= 运动户外 (21-25) =================
  Product(
    id: 21,
    name: '户外超轻便携折叠月亮椅',
    description: '航空铝合金支架结构，600D加厚防撕裂牛津布，承重可达150KG。',
    category: '运动户外',
    cover: 'https://picsum.photos/seed/p21_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p21_img1/800/800',
      'https://picsum.photos/seed/p21_img2/800/800',
      'https://picsum.photos/seed/p21_img3/800/800',
    ],
    price: 129.00,
    remark: '附赠便携收纳包 / 净重仅0.98kg',
  ),
  Product(
    id: 22,
    name: '双面防滑加厚瑜伽垫 8mm',
    description: '环保TPE材质，正面体位引导线设计，波浪防滑底纹抓地稳固。',
    category: '运动户外',
    cover: 'https://picsum.photos/seed/p22_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p22_img1/800/800',
      'https://picsum.photos/seed/p22_img2/800/800',
      'https://picsum.photos/seed/p22_img3/800/800',
    ],
    price: 88.00,
    remark: '回弹无异味 / 赠绑带及透气网包',
  ),
  Product(
    id: 23,
    name: '深层肌肉放松迷你筋膜枪',
    description: '无刷强劲电机输出，四档物理振动调节，深度击溃运动乳酸堆积。',
    category: '运动户外',
    cover: 'https://picsum.photos/seed/p23_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p23_img1/800/800',
      'https://picsum.photos/seed/p23_img2/800/800',
      'https://picsum.photos/seed/p23_img3/800/800',
    ],
    price: 259.00,
    remark: '配4款专业按摩头 / Type-C通用充电',
  ),
  Product(
    id: 24,
    name: '大容量不锈钢户外保温壶 1000ml',
    description: '双层316医用级不锈钢内胆，强效锁温保冷24小时，提环便携防摔。',
    category: '运动户外',
    cover: 'https://picsum.photos/seed/p24_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p24_img1/800/800',
      'https://picsum.photos/seed/p24_img2/800/800',
      'https://picsum.photos/seed/p24_img3/800/800',
    ],
    price: 139.00,
    remark: '食品级硅胶密封圈 / 360°密封防漏',
  ),
  Product(
    id: 25,
    name: 'UPF50+ 户外速干防晒皮肤衣',
    description: '科技防紫外线冰感面料，高效阻隔99%紫外线，腋下透气微孔拼接。',
    category: '运动户外',
    cover: 'https://picsum.photos/seed/p25_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p25_img1/800/800',
      'https://picsum.photos/seed/p25_img2/800/800',
      'https://picsum.photos/seed/p25_img3/800/800',
    ],
    price: 179.00,
    remark: '轻盈无感 / 附带防紫外线加宽帽檐',
  ),

  // ================= 办公文具 (26-30) =================
  Product(
    id: 26,
    name: '全铝合金折叠升降笔记本支架',
    description: '双轴无极调节高度与视角，镂空散热底板，加厚硅胶防滑抗刮。',
    category: '办公文具',
    cover: 'https://picsum.photos/seed/p26_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p26_img1/800/800',
      'https://picsum.photos/seed/p26_img2/800/800',
      'https://picsum.photos/seed/p26_img3/800/800',
    ],
    price: 98.00,
    remark: '承重10kg / 兼容11-17.3英寸设备',
  ),
  Product(
    id: 27,
    name: '经典商务金属钢笔礼盒套装',
    description: '精工不锈钢F尖，下墨均匀顺滑，黄铜漆面笔身，配旋转吸墨器与非碳素墨水。',
    category: '办公文具',
    cover: 'https://picsum.photos/seed/p27_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p27_img1/800/800',
      'https://picsum.photos/seed/p27_img2/800/800',
      'https://picsum.photos/seed/p27_img3/800/800',
    ],
    price: 168.00,
    remark: '赠50ml墨水+精美硬壳礼盒包装',
  ),
  Product(
    id: 28,
    name: 'A5商务磁扣皮质日程笔记本',
    description: '采用100g道林护眼纸，书写不易透墨，磁吸开合搭扣内嵌插笔位。',
    category: '办公文具',
    cover: 'https://picsum.photos/seed/p28_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p28_img1/800/800',
      'https://picsum.photos/seed/p28_img2/800/800',
      'https://picsum.photos/seed/p28_img3/800/800',
    ],
    price: 45.00,
    remark: '内置双书签带 / 180度平摊装订',
  ),
  Product(
    id: 29,
    name: '双光源减蓝光LED护眼长臂台灯',
    description: '国AA级照度标准，微菱晶防眩光面板，金属双节机械折叠臂任意悬停。',
    category: '办公文具',
    cover: 'https://picsum.photos/seed/p29_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p29_img1/800/800',
      'https://picsum.photos/seed/p29_img2/800/800',
      'https://picsum.photos/seed/p29_img3/800/800',
    ],
    price: 239.00,
    remark: '显色指数Ra≥95 / 智能环境光感应',
  ),
  Product(
    id: 30,
    name: '加厚软质毛毡办公桌垫 90x40cm',
    description: '天然羊毛混纺毛毡，质感温润吸音，背面环保滴胶颗粒强效防滑。',
    category: '办公文具',
    cover: 'https://picsum.photos/seed/p30_cover/800/800',
    imgs: [
      'https://picsum.photos/seed/p30_img1/800/800',
      'https://picsum.photos/seed/p30_img2/800/800',
      'https://picsum.photos/seed/p30_img3/800/800',
    ],
    price: 39.90,
    remark: '精密锁边工艺 / 支持鼠标顺畅滑动',
  ),
];

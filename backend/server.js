import 'dotenv/config';
import express from 'express';
import multer from 'multer';
import { GoogleGenAI } from '@google/genai';

const app = express();
const port = Number(process.env.PORT || 3000);

if (!process.env.GEMINI_API_KEY) {
  console.error('Chưa cấu hình GEMINI_API_KEY trong file .env');
  process.exit(1);
}

const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
});

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 8 * 1024 * 1024,
  },
});

const schema = {
  type: 'object',
  properties: {
    foods: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          name: {
            type: 'string',
          },
          portion_grams: {
            type: 'number',
          },
          calories_kcal: {
            type: 'number',
          },
          protein_g: {
            type: 'number',
          },
          carbs_g: {
            type: 'number',
          },
          fat_g: {
            type: 'number',
          },
        },
        required: [
          'name',
          'portion_grams',
          'calories_kcal',
          'protein_g',
          'carbs_g',
          'fat_g',
        ],
      },
    },
    note: {
      type: 'string',
    },
  },
  required: ['foods', 'note'],
};

app.get('/', (req, res) => {
  res.json({
    message: 'Health App Food AI API is running',
  });
});

app.post(
  '/analyze-food',
  upload.single('image'),
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({
          error: 'Vui lòng gửi ảnh món ăn.',
        });
      }

      const allowedTypes = [
        'image/jpeg',
        'image/png',
        'image/webp',
        'image/heic',
        'image/heif',
      ];

      const extension = req.file.originalname
        .toLowerCase()
        .split('.')
        .pop();

      const mimeByExtension = {
        jpg: 'image/jpeg',
        jpeg: 'image/jpeg',
        png: 'image/png',
        webp: 'image/webp',
        heic: 'image/heic',
        heif: 'image/heif',
      };

      const mimeType = allowedTypes.includes(req.file.mimetype)
        ? req.file.mimetype
        : mimeByExtension[extension];

      if (!mimeType) {
        return res.status(400).json({
          error:
            'Ảnh không được hỗ trợ. Hãy chọn JPG, PNG hoặc WebP.',
        });
      }

      const prompt = [
        'Bạn là trợ lý ước tính dinh dưỡng từ ảnh món ăn.',
        'Trả kết quả bằng tiếng Việt theo JSON schema.',
        'Nhận diện từng món ăn có thể nhìn thấy rõ trong ảnh.',
        'Không tự thêm món ăn không xuất hiện trong ảnh.',
        'Ước tính khối lượng phần ăn được bằng gram.',
        'Ước tính calo, protein, carbohydrate và chất béo',
        'cho khẩu phần của từng món.',
        'Tất cả số liệu phải không âm.',
        'Không khẳng định số liệu chính xác tuyệt đối.',
        'Không thể xác định chính xác khối lượng chỉ từ ảnh.',
        'Nếu không nhận diện được món ăn, trả foods là mảng rỗng',
        'và giải thích ngắn gọn trong note.',
      ].join(' ');

      const result = await ai.models.generateContent({
        model: 'gemini-3.5-flash-lite',
        contents: [
          {
            role: 'user',
            parts: [
              {
                text: prompt,
              },
              {
                inlineData: {
                  mimeType: mimeType,
                  data: req.file.buffer.toString('base64'),
                },
              },
            ],
          },
        ],
        config: {
          responseMimeType: 'application/json',
          responseJsonSchema: schema,
        },
      });

      if (!result.text) {
        return res.status(502).json({
          error: 'AI không trả về kết quả.',
        });
      }

      const data = JSON.parse(result.text);

      return res.json(data);
    } catch (error) {
      console.error('Lỗi Gemini:', error);

      const status = error.status ?? error.statusCode;

      if (status === 429) {
        return res.status(429).json({
          error:
            'Gemini đã báo vượt hạn mức API. ' +
            'Hãy kiểm tra quota của project.',
        });
      }

      if (status === 503) {
        return res.status(503).json({
          error:
            'Gemini đang quá tải. Vui lòng thử lại sau.',
        });
      }

      return res.status(500).json({
        error:
          'Không thể phân tích ảnh. ' +
          'Hãy kiểm tra API key và cấu hình Gemini.',
      });
    }
  },
);

// Xử lý lỗi tải ảnh
app.use((error, req, res, next) => {
  if (error instanceof multer.MulterError) {
    const status =
      error.code === 'LIMIT_FILE_SIZE' ? 413 : 400;

    return res.status(status).json({
      error:
        error.code === 'LIMIT_FILE_SIZE'
          ? 'Ảnh quá lớn. Vui lòng chọn ảnh dưới 8 MB.'
          : 'Không thể tải ảnh lên.',
    });
  }

  console.error('Lỗi máy chủ:', error);

  return res.status(500).json({
    error: 'Máy chủ gặp lỗi.',
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Food AI API đang chạy tại cổng ${port}`);
});